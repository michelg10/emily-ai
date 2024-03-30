import cv2
import pytesseract

img = cv2.imread('imgs/gmail.png')

#=========TEXT==========#

custom_config = r'--oem 3 --psm 3'

# Convert image to grayscale
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Apply threshold to convert to binary image
threshold_img = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]

h, w, c = img.shape
boxes = pytesseract.image_to_boxes(threshold_img) 

lstStrBoxes = boxes.splitlines()
lstBoxes = []
for box in lstStrBoxes:
    b = box.split(' ')
    for i in range(1, 5):
        b[i] = int(b[i])
    lstBoxes.append(b)

# Dict implementation

blockPixelSep = 15
wordPixelSep = 7
horizPadding = 6
vertPadding = 5
dictContent = {}
word = ""
box = [0, 0, 0, 0]
boxInit = False
for i in range(len(lstBoxes)):
    if i < len(lstBoxes) - 1 and abs(lstBoxes[i][3] - lstBoxes[i+1][1]) < blockPixelSep:

        if boxInit == False:
            boxInit = True
            box[0] = lstBoxes[i][1] - horizPadding
            box[1] = h - lstBoxes[i][2]
            box[3] = h - lstBoxes[i][4]
            word += lstBoxes[i][0]
        else:
            box[1] = max(box[1], h - lstBoxes[i][2])
            box[3] = min(box[3], h - lstBoxes[i][4])
            word += lstBoxes[i][0]

        if abs(lstBoxes[i][3] - lstBoxes[i+1][1]) > wordPixelSep:
            word += " "
    else:
        if boxInit == True:
            box[1] = max(box[1], h - lstBoxes[i][2]) + vertPadding
            box[3] = min(box[3], h - lstBoxes[i][4]) - vertPadding
            word += lstBoxes[i][0]

            boxInit = False
            box[2] = lstBoxes[i][3] + horizPadding
            dictContent[word] = box
            word = ""
            box = [0, 0, 0, 0]
        else:
            dictContent[lstBoxes[i][0]] = [lstBoxes[i][1], h - lstBoxes[i][2], lstBoxes[i][3], h - lstBoxes[i][4]]


for word in dictContent:
    box = dictContent[word]
    print(word, " ")
    img = cv2.rectangle(img, (box[0], box[1]), (box[2], box[3]), (0, 255, 0), 2)

cv2.imshow('img', img)
cv2.waitKey(0)
# cv2.imwrite('annotated/gmail-annotated.png', img)