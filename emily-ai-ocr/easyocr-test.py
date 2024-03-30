import cv2
import easyocr

img = cv2.imread('imgs/gmail.png')
reader = easyocr.Reader(['en'], detector='dbnet18')
result = reader.readtext(img)
# print(result)

for bbox, text, score in result:
    cv2.rectangle(img, tuple(map(int, bbox[0])), tuple(map(int, bbox[2])), (0, 255, 0), 5)
    cv2.putText(img, text, tuple(map(int, bbox[0])), cv2.FONT_HERSHEY_COMPLEX_SMALL, 0.65, (255, 0, 0), 2)

cv2.imshow('img', img)
cv2.waitKey(0)