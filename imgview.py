import sys
import numpy as np
from PyQt6.QtWidgets import (
    QApplication, QLabel, QMainWindow, QFileDialog, QPushButton, QVBoxLayout, QWidget,
    QInputDialog, QMessageBox
)
from PyQt6.QtGui import QPixmap, QImage
from PyQt6.QtCore import Qt

class FullRawYUVViewer(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Full RAW/YUV Viewer & Converter")
        self.setGeometry(100, 100, 1000, 700)

        self.label = QLabel("Open a RAW or YUV file", self)
        self.label.setAlignment(Qt.AlignmentFlag.AlignCenter)

        open_button = QPushButton("Open Image", self)
        open_button.clicked.connect(self.open_file)

        convert_button = QPushButton("Convert RAW to YUV", self)
        convert_button.clicked.connect(self.convert_to_yuv)

        layout = QVBoxLayout()
        layout.addWidget(self.label)
        layout.addWidget(open_button)
        layout.addWidget(convert_button)

        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

        self.rgb_image = None
        self.width = None
        self.height = None

    def open_file(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Open RAW/YUV", "", "All Files (*)")
        if not file_path:
            return

        img_type, ok = QInputDialog.getItem(self, "Image Type", "Select image type:", ["RAW", "YUV"], 0, False)
        if not ok: return

        width, ok = QInputDialog.getInt(self, "Width", "Enter image width:", 512, 1, 100000)
        if not ok: return
        height, ok = QInputDialog.getInt(self, "Height", "Enter image height:", 512, 1, 100000)
        if not ok: return
        stride, ok = QInputDialog.getInt(self, "Stride", "Enter stride (bytes per row):", width, 1, 100000)
        if not ok: return

        self.width = width
        self.height = height

        try:
            with open(file_path, "rb") as f:
                raw_data = f.read()

            if img_type == "RAW":
                bit_depth, ok = QInputDialog.getInt(self, "Bit Depth", "Enter bit depth (10/12/14/16):", 16, 8, 16)
                if not ok: return

                if bit_depth == 16:
                    raw_pixels = np.frombuffer(raw_data, dtype='>u2', count=height*stride//2)
                else:
                    packed_type, ok = QInputDialog.getItem(self, "Packed/Unpacked", "Select RAW type:", ["Unpacked", "Packed"], 0, False)
                    if not ok: return
                    if packed_type == "Unpacked":
                        raw_pixels = np.frombuffer(raw_data, dtype='>u2', count=height*stride//2)
                    else:
                        raw_pixels = self.unpack_packed(raw_data, width, height, bit_depth)

                raw_pixels = raw_pixels[:height*width].reshape((height, width))
                raw_pixels = (raw_pixels.astype(np.float32)/(2**bit_depth-1)*255).astype(np.uint8)
                self.rgb_image = np.stack([raw_pixels]*3, axis=-1)

            else:  # YUV input
                yuv_formats = ["YUV420p", "YUV422p", "YUV444p", "NV12", "NV21"]
                yuv_fmt, ok = QInputDialog.getItem(self, "YUV Format", "Select YUV format:", yuv_formats, 0, False)
                if not ok: return
                self.rgb_image = self.yuv_to_rgb(raw_data, width, height, stride, yuv_fmt)

            qimg = QImage(self.rgb_image.data, width, height, 3*width, QImage.Format.Format_RGB888)
            pixmap = QPixmap.fromImage(qimg)
            self.label.setPixmap(pixmap.scaled(self.label.size(), Qt.AspectRatioMode.KeepAspectRatio))
            self.setWindowTitle(f"Viewer - {file_path}")

        except Exception as e:
            self.label.setText(f"Failed to open image:\n{str(e)}")

    def unpack_packed(self, data, width, height, bit_depth):
        """Unpack 10/12/14-bit packed RAW into uint16"""
        total_pixels = width*height
        byte_data = np.frombuffer(data, dtype=np.uint8)
        output = np.zeros(total_pixels, dtype=np.uint16)

        if bit_depth == 10:
            for i in range(0, total_pixels, 4):
                idx = i//4*5
                b = byte_data[idx:idx+5]
                b = np.pad(b,(0,5-len(b)))
                output[i]   = ((b[0]<<2)|(b[4]&0x03))
                output[i+1] = ((b[1]<<2)|((b[4]>>2)&0x03))
                output[i+2] = ((b[2]<<2)|((b[4]>>4)&0x03))
                output[i+3] = ((b[3]<<2)|((b[4]>>6)&0x03))
        elif bit_depth == 12:
            for i in range(0, total_pixels, 2):
                idx = i//2*3
                b = byte_data[idx:idx+3]
                b = np.pad(b,(0,3-len(b)))
                output[i]   = (b[0]<<4)|(b[1]>>4)
                output[i+1] = ((b[1]&0x0F)<<8)|b[2]
        elif bit_depth == 14:
            for i in range(0, total_pixels, 4):
                idx = i//4*7
                b = byte_data[idx:idx+7]
                b = np.pad(b,(0,7-len(b)))
                output[i]   = (b[0]<<6)|(b[4]&0x3F)
                output[i+1] = (b[1]<<6)|((b[4]>>6)&0x03)|((b[5]&0x0F)<<2)
                output[i+2] = (b[2]<<6)|((b[5]>>4)&0x0F)
                output[i+3] = (b[3]<<6)|((b[5]&0x3F))
        else:
            raise ValueError("Unsupported packed bit depth")
        return output

    def yuv_to_rgb(self, data, width, height, stride, fmt):
        yuv = np.frombuffer(data, dtype=np.uint8)
        if fmt == "YUV420p":
            y_size = width*height
            uv_size = y_size//4
            Y = yuv[0:y_size].reshape((height,width))
            U = yuv[y_size:y_size+uv_size].reshape((height//2,width//2)).repeat(2, axis=0).repeat(2, axis=1)
            V = yuv[y_size+uv_size:].reshape((height//2,width//2)).repeat(2, axis=0).repeat(2, axis=1)
        elif fmt == "YUV422p":
            y_size = width*height
            uv_size = y_size//2
            Y = yuv[0:y_size].reshape((height,width))
            U = yuv[y_size:y_size+uv_size//2].reshape((height,width//2)).repeat(1, axis=0).repeat(2, axis=1)
            V = yuv[y_size+uv_size//2:y_size+uv_size].reshape((height,width//2)).repeat(1, axis=0).repeat(2, axis=1)
        elif fmt == "YUV444p":
            Y = yuv[0:width*height].reshape((height,width))
            U = yuv[width*height:2*width*height].reshape((height,width))
            V = yuv[2*width*height:3*width*height].reshape((height,width))
        elif fmt == "NV12":
            Y = yuv[0:width*height].reshape((height,width))
            UV = yuv[width*height:].reshape((height//2,width))
            U = UV[:,0::2].repeat(2, axis=0).repeat(2, axis=1)
            V = UV[:,1::2].repeat(2, axis=0).repeat(2, axis=1)
        elif fmt == "NV21":
            Y = yuv[0:width*height].reshape((height,width))
            VU = yuv[width*height:].reshape((height//2,width))
            V = VU[:,0::2].repeat(2, axis=0).repeat(2, axis=1)
            U = VU[:,1::2].repeat(2, axis=0).repeat(2, axis=1)
        else:
            raise ValueError("Unsupported YUV format")

        Y = Y.astype(np.float32)
        U = U.astype(np.float32)-128
        V = V.astype(np.float32)-128
        R = Y + 1.402*V
        G = Y -0.344136*U -0.714136*V
        B = Y +1.772*U
        rgb = np.stack([R,G,B], axis=-1)
        np.clip(rgb,0,255,out=rgb)
        return rgb.astype(np.uint8)

    def convert_to_yuv(self):
        if self.rgb_image is None:
            QMessageBox.warning(self, "Error", "No RAW image loaded")
            return

        yuv_formats = ["YUV420p", "YUV422p", "YUV444p", "NV12", "NV21"]
        yuv_fmt, ok = QInputDialog.getItem(self, "YUV Format", "Select YUV format:", yuv_formats, 0, False)
        if not ok: return

        rgb = self.rgb_image.astype(np.float32)
        R,G,B = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]
        Y = 0.299*R + 0.587*G + 0.114*B
        U = -0.169*R -0.331*G +0.5*B +128
        V = 0.5*R -0.419*G -0.081*B +128
        Y = np.clip(Y,0,255).astype(np.uint8)
        U = np.clip(U,0,255).astype(np.uint8)
        V = np.clip(V,0,255).astype(np.uint8)

        h,w = self.height, self.width
        yuv_data = b""

        if yuv_fmt=="YUV420p":
            yuv_data += Y.tobytes()
            U_420 = U.reshape(h//2,2,w//2,2).mean(axis=(1,3)).astype(np.uint8)
            V_420 = V.reshape(h//2,2,w//2,2).mean(axis=(1,3)).astype(np.uint8)
            yuv_data += U_420.tobytes()
            yuv_data += V_420.tobytes()
        elif yuv_fmt=="YUV422p":
            yuv_data += Y.tobytes()
            U_422 = U.reshape(h,w//2,2).mean(axis=2).astype(np.uint8)
            V_422 = V.reshape(h,w//2,2).mean(axis=2).astype(np.uint8)
            yuv_data += U_422.tobytes()
            yuv_data += V_422.tobytes()
        elif yuv_fmt=="YUV444p":
            yuv_data += Y.tobytes() + U.tobytes() + V.tobytes()
        elif yuv_fmt=="NV12":
            yuv_data += Y.tobytes()
            UV = np.empty((h//2,w),dtype=np.uint8)
            UV[:,0::2] = U[0::2,0::2]
            UV[:,1::2] = V[0::2,0::2]
            yuv_data += UV.tobytes()
        elif yuv_fmt=="NV21":
            yuv_data += Y.tobytes()
            VU = np.empty((h//2,w),dtype=np.uint8)
            VU[:,0::2] = V[0::2,0::2]
            VU[:,1::2] = U[0::2,0::2]
            yuv_data += VU.tobytes()

        save_path, _ = QFileDialog.getSaveFileName(self, "Save YUV File", "", "YUV Files (*.yuv)")
        if save_path:
            with open(save_path,"wb") as f:
                f.write(yuv_data)
            QMessageBox.information(self, "Saved", f"YUV saved to {save_path}")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    viewer = FullRawYUVViewer()
    viewer.show()
    sys.exit(app.exec())
