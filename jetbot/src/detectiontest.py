# Used to test an object detection model through the camera feed. Just update the locations of your model/labels.

import jetson.inference
import jetson.utils
import argparse
import sys
import keyboard

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

    # load the recognition network
    #collision_net = jetson.inference.imageNet(argv=['--model=/home/jetbot/jetbot/models/intersection-resnet18.onnx', '--labels=/home/jetbot/jetbot/models/intersection-labels.txt', '--input-blob=input_0', '--output-blob=output_0'])
    sign_net = jetson.inference.detectNet(argv=['--threshold=0.5','--model=/home/jetbot/jetbot/models/green-line.onnx', '--labels=/home/jetbot/jetbot/models/green-line-labels.txt', '--input-blob=input_0', '--output-cvg=scores', '--output-bbox=boxes'])
    #detect_net = jetson.inference.detectNet(argv=['--model=/home/jetbot/jetbot/models/detection-ssd-mobilenet.onnx', '--labels=/home/jetbot/jetbot/models/detection-labels.txt', '--input-blob=input_0', '--output-cvg=scores', '--output-bbox=boxes'] )

    # create video sources & outputs
    camera1 = jetson.utils.videoSource("csi://0", argv=sys.argv)
    #camera2 = jetson.utils.videoSource("csi://1", argv=sys.argv)

    display = jetson.utils.videoOutput("rtp://10.128.204.167:1234", argv=sys.argv + is_headless)
    font = jetson.utils.cudaFont()

    # process frames until the user exits
    while True:

        # capture the next image
        image1 = camera1.Capture()
        #image2 = camera2.Capture()
        
        #new_width = image1.width + image2.width
        #new_height=max(image1.height, image2.height)
        
        # combining the images from the two cameras
        # allocate the output image, with dimensions to fit both inputs side-by-side
        #final_image = jetson.utils.cudaAllocMapped(width=new_width, height=new_height, format="rgb8")

        # compost the two images (the last two arguments are x,y coordinates in the output image)
        #jetson.utils.cudaOverlay(image1, final_image, 0, 0)
        #jetson.utils.cudaOverlay(image2, final_image, image1.width, 0)


        ######## Collision Avoidance Model
        
        # running classification model on the combined image
        # classify the image
        #col_id, col_confidence = collision_net.Classify(final_image)
        #print(col_id)
        #print(col_confidence)

        # find the object description
        #col_desc = collision_net.GetClassDesc(col_id)
        
        # # overlay the result on the image
        #font.OverlayText(final_image, final_image.width, final_image.height, "{:05.2f}% {:s}".format(col_confidence * 100, col_desc), 5, 5, font.White, font.Gray40)
        
        ######## Intersection Model

        # running classification model on the combined image
        # classify the image
        #int_id, int_confidence = intersection_net.Classify(final_image)
        #print(int_id)
        #print(int_confidence)

        # find the object description
        #int_desc = intersection_net.GetClassDesc(int_id)
        
        # # overlay the result on the image
        #font.OverlayText(final_image, final_image.width, final_image.height, "{:05.2f}% {:s}".format(int_confidence * 100, int_desc), 5, 50, font.White, font.Gray40)
        signs = sign_net.Detect(image1, overlay=opt.overlay)
        #print("detected {:d} objects in image".format(len(lines)))
        #for line in lines:
            #print(line.Area)
    

        ######## Detection Model
        
        # running object detection model on the combined image
        # detect objects in the image (with overlay)
        #detections = detect_net.Detect(final_image, overlay=opt.overlay)

        # print the detections
        #print("detected {:d} objects in image".format(len(detections)))

        #for detection in detections:
        #    print(detection.Area)
        
        #displaying the image
        # render the image
        display.Render(image1)

        # update the title bar
        #display.SetStatus("{:s} | Network {:.0f} FPS".format(collision_net.GetNetworkName(), collision_net.GetNetworkFPS()))
        #display.SetStatus("{:s} | Network {:.0f} FPS".format(intersection_net.GetNetworkName(), intersection_net.GetNetworkFPS()))

        # print out performance info
        #collision_net.PrintProfilerTimes()
        #intersection_net.PrintProfilerTimes()
        #detect_net.PrintProfilerTimes()

        # press 'Q' to stop
        if keyboard.is_pressed('q'):
            print('Stop')
            break
        # exit on input/output EOS
        if not (camera1.IsStreaming()) or not display.IsStreaming():
            break
