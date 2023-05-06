import sys
sys.path.insert(1, '/home/jetbot/jetbot/')
 
import jetson.inference
import jetson.utils
import argparse

import torch
from torch2trt import TRTModule
import torchvision.transforms as transforms
import torch.nn.functional as F

import cv2
import PIL.Image
import numpy as np

import os
import keyboard
import time
import datetime
import inputs
import threading

from jetbot import Robot
robot = Robot()

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="Classify a live camera stream using an image recognition DNN.",
                                        formatter_class=argparse.RawTextHelpFormatter,
                                        epilog=jetson.inference.imageNet.Usage() +
                                                jetson.utils.videoSource.Usage() + jetson.utils.videoOutput.Usage() + jetson.utils.logUsage())
    parser.add_argument("input_URI", type=str, default="", nargs='?', help="URI of the input stream")
    parser.add_argument("output_URI", type=str, default="", nargs='?', help="URI of the output stream")
    parser.add_argument("--network", type=str, default="resnet18",
                        help="pre-trained model to load (see below for options)")
    parser.add_argument("--overlay", type=str, default="box,labels,conf", help="detection overlay flags (e.g. --overlay=box,labels,conf)\nvalid combinations are:  'box', 'labels', 'conf', 'none'")
    parser.add_argument("--threshold", type=float, default=0.5, help="minimum detection threshold to use") 
    parser.add_argument("--camera", type=str, default="0",
                        help="index of the MIPI CSI camera to use (e.g. CSI camera 0)\nor for VL42 cameras, the /dev/video device to use.\nby default, MIPI CSI camera 0 will be used.")
    parser.add_argument("--width", type=int, default=640, help="desired width of camera stream (default is 1280 pixels)")
    parser.add_argument("--height", type=int, default=720, help="desired height of camera stream (default is 720 pixels)")
    parser.add_argument('--headless', action='store_true', default=(), help="run without display")

    # For rtp streaming
    is_headless = ["--headless"] if sys.argv[0].find('console.py') != -1 else [""]
    
    try:
        opt = parser.parse_known_args()[0]
    except:
        print("")
        parser.print_help()
        sys.exit(0)

    state = "rf" # The robot starts with road following.
    strikes = 0

    # load the recognition network (object detection models)
    # intersection_net = jetson.inference.detectNet(argv=['--model=/home/jetbot/jetbot/models/intersect.onnx', '--labels=/home/jetbot/jetbot/models/intersection-labels.txt', '--input-blob=input_0', '--output-cvg=scores', '--output-bbox=boxes', '--threshold=0.3'])
    sign_net = jetson.inference.detectNet(argv=['--model=/home/jetbot/jetbot/models/full-signs.onnx', '--labels=/home/jetbot/jetbot/models/sign-labels.txt', '--input-blob=input_0', '--output-cvg=scores', '--output-bbox=boxes'] )
    rf_net = jetson.inference.detectNet(argv=['--model=/home/jetbot/jetbot/models/green-line.onnx', '--labels=/home/jetbot/jetbot/models/green-line-labels.txt', '--input-blob=input_0', '--output-cvg=scores', '--output-bbox=boxes'] )

    # create video sources & outputs
    camera1 = jetson.utils.videoSource("csi://0", argv=sys.argv)

    #display = jetson.utils.videoOutput("display://0", argv=sys.argv + is_headless)

    #### ADJUST IP ADDRESS to match the laptop's here
    display = jetson.utils.videoOutput("rtp://10.131.4.57:1234", argv=sys.argv + is_headless)

    font = jetson.utils.cudaFont()

    # process frames until the user exits
    while True:
        # capture the next image
        image1 = camera1.Capture()
        
        
        ###### ROAD FOLLOWING AND SIGN DETECTION #######
        # At any given time, the robot will be focused on either
        # road following or responding to signs.
        # These are represented by different "states."
        # All the motor values are hardcoded. Particularly for turns, you may need to adjust the values to fit your course.

        if state == "rf":
            # Look for road line. 
            road_lines = rf_net.Detect(image1, overlay=opt.overlay)
            if len(road_lines) == 0:
                strikes += 1
                if strikes == 8:
                    # After the robot fails to detect any road lines many frames in a row,
                    # stop and look for signs.
                    state = "signs"
                    strikes = 0
                    robot.stop()
            else:
                strikes = 0
                for rl in road_lines:
                    # The robot only cares about green lines at the bottom of the image.
                    if rl.Bottom > 2 * image1.height / 3:
                        print(rl.Left, rl.Right)

                        # Adjust if the sign is fully on one side.
                        # Otherwise, continue straight.
                        if rl.Left > image1.width/2:
                            robot.set_motors(0.15, 0.1)
                        elif rl.Right < image1.width/2:
                            robot.set_motors(0.1, 0.15)
                        else:
                            robot.set_motors(0.15, 0.15)
        elif state == "signs":
            # Look for signs.
            signs = sign_net.Detect(image1, overlay=opt.overlay)
            if len(signs) == 0:
                strikes += 1
                if strikes == 3:
                    # After the robot fails to detect any signs 3 frames in a row,
                    # proceed straight forward, then stop and look for the road.
                    print("STRAIGHT")
                    robot.set_motors(0.142, 0.14)
                    time.sleep(3.7)
                    state = "rf"
                    strikes = 0
                    robot.stop()
            else:
                strikes = 0
                for sign in signs:
                    # The robot may see other signs, but it only cares about the
                    # the right side of the image - that's where the sign is placed.
                    if sign.Left > image1.width/2 and sign.Area > image1.width * image1.height / 50:
                        # Turn depending on what sign is detected,
                        # then stop and look for the road.
                        if sign.ClassID == 1:
                            print("LEFT")
                            robot.set_motors(0.15, 0.15)
                            time.sleep(0.5)
                            robot.set_motors(0.17, 0.2)
                            time.sleep(3.3)
                            robot.stop()
                            state = "rf"
                        elif sign.ClassID == 2:
                            print("RIGHT")
                            robot.set_motors(0.15, 0.15)
                            time.sleep(0.4)
                            robot.set_motors(0.19, 0.13)
                            time.sleep(2.0)
                            robot.stop()
                            state = "rf"
                        elif sign.ClassID == 3:
                            print("U-TURN")
                            robot.set_motors(0.1, 0.22)
                            time.sleep(2.5)
                            robot.stop()
                            state = "rf"
        
        ######## Collision Avoidance Model
        ######## Intersection Model
        ### This was old experimentation for detecting other cars or the intersection.
        ### This part is currently not in use, but it's here in case you want to experiment.
        
        # # overlay the result on the image
        #font.OverlayText(final_image, final_image.width, final_image.height, "{:05.2f}% {:s}".format(int_confidence * 100, int_desc), 5, 50, font.White, font.Gray40)
        # lines = intersection_net.Detect(contrast_img, overlay=opt.overlay)
        
        # #print("detected {:d} lines in image".format(len(lines)))
        # for index, line in enumerate(lines, start=1):
        #     print("LINE NUMBER " + str(index))
        #     print("---------------------------------------------------")
        #     print("area of bounding box: " + str(line.Area))
        #     print("center of bounding box: " + str(line.Center))
        #     print("left of line: " + str(line.Left), "right of line: " + str(line.Right))
        #     print("---------------------------------------------------")

        # if (len(lines)>4):
        #     robot.stop()

        # signs = sign_net.Detect(contrast_img, overlay=opt.overlay)
        # #print("detected {:d} signs in image".format(len(signs)))
        # #display.Render(contrast_image)
        # for index, sign in enumerate(signs, start=1):
        #     print("SIGN NUMBER " + str(index))
        #     print("---------------------------------------------------")
        #     print("area of bounding box: " + str(sign.Area))
        #     print("center of bounding box: " + str(sign.Center))
        #     print("left of sign: " + str(sign.Left), "right of sign: " + str(sign.Right))
        #     print("---------------------------------------------------")
        #     #if (sign.Area > 110000):
        #         #robot.set_motors(0,0.3)
        #         #time.sleep(1)

        #displaying the image
        # render the image
        display.Render(image1)

        # print out performance info
        #collision_net.PrintProfilerTimes()
        #intersection_net.PrintProfilerTimes()
        #detect_net.PrintProfilerTimes()

        if keyboard.is_pressed('q'):
            print('Stop')
            break
        # exit on input/output end of stream
        if not camera1.IsStreaming() or not display.IsStreaming():
            break
