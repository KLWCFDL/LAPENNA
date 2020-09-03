A = imread("Lenna.jpg");

kernel = [-1 -1 -1; -1 8 -1; -1 -1 -1];

X = uint8(convn(A, kernel));

imshow(X);
imwrite(X,"peppers.jpeg");
