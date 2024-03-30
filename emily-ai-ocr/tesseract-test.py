import cv2
import pytesseract

# img = cv2.imread('chrome.png')
img = cv2.imread('gmail.png')

#=========TEXT==========#

custom_config = r'--oem 3 --psm 3'

# Convert image to grayscale
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Apply threshold to convert to binary image
threshold_img = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]

# Pass the image through pytesseract
text = pytesseract.image_to_string(threshold_img, config=custom_config)

# print(text)

#=============BOUNDING=============#

h, w, c = img.shape
boxes = pytesseract.image_to_boxes(threshold_img) 
# for b in boxes.splitlines():
#     b = b.split(' ')
    # img = cv2.rectangle(img, (int(b[1]), h - int(b[2])), (int(b[3]), h - int(b[4])), (0, 255, 0), 2)

# cv2.imshow('img', img)
# cv2.waitKey(0)

print("============Thresholded image============")

# Simple image to string
# print(pytesseract.image_to_string(threshold_img))

# Get bounding box estimates
# print(pytesseract.image_to_boxes(threshold_img))

# Get verbose data including boxes, confidences, line and page numbers
# print(pytesseract.image_to_data(threshold_img))


#==============MERGING BOXES================

print("===============MERGING BOXES===================")

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
dictContent = {}
word = ""
box = [0, 0, 0, 0]
boxInit = False
for i in range(len(lstBoxes)):
    if i < len(lstBoxes) - 1 and abs(lstBoxes[i][3] - lstBoxes[i+1][1]) < blockPixelSep:

        if boxInit == False:
            boxInit = True
            box[0] = lstBoxes[i][1]
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
            box[1] = max(box[1], h - lstBoxes[i][2])
            box[3] = min(box[3], h - lstBoxes[i][4])
            word += lstBoxes[i][0]

            boxInit = False
            box[2] = lstBoxes[i][3]
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



# List implementation

# lstContent = []
# word = ""
# box = [0, 0, 0, 0]
# boxInit = False
# for i in range(lstBoxes):
#     if i != len(lstBoxes) and abs(lstBoxes[i][3] - lstBoxes[i+1][1]) < pixelOffset:
#         if boxInit == False:
#             boxInit = True
#             box[0] = lstBoxes[i][1]
#             box[1] = h - lstBoxes[i][2]
#             word += lstBoxes[i][0]
#         else:
#             word += lstBoxes[i][0]
#     else:
#         if boxInit == True:
#             boxInit = False
#             box[2] = lstBoxes[i-1][3]
#             box[3] = lstBoxes[i-1][4]
#             lstContent.append({word: box})
#             word = ""
#             box = [0, 0, 0, 0]


# for content in lstContent:
#     img = cv2.rectangle(img, (int(b[1]), h - int(b[2])), (int(b[3]), h - int(b[4])), (0, 255, 0), 2)
