
import numpy as np

a = np.ones([9, 5, 7, 4])
b = np.ones([9, 5, 4, 3])

print("The shape of a is {}".format(a.shape))
print("The shape of b is {}".format(b.shape))

print("the shape of a dot b is {}".format(np.dot(a, b).shape))

print("the shape of the matrix matrix multiplication of a and b is {}".format(np.matmul(a, b).shape))

c = np.array([[1, 0],
              [0, 1]])

d = np.array([[4, 1],
              [2, 2]])

print("c = \n{}".format(c))
print("d = \n{}".format(d))

print("c * d = \n{}".format(np.matmul(c, d)))