﻿#include ImagePut.ahk

ImageEqual(images*) {
   return ImageEqual.call(images*)
}

class ImageEqual extends ImagePut {

   call(images*) {
      if (images.Count() == 0)
         return false

      if (images.Count() == 1)
         return true

      this.gdiplusStartup()

      ; Convert the images to pBitmaps (byte arrays).
      for i, image in images {
         try type := this.DontVerifyImageType(image)
         catch
            try type := this.ImageType(image)
            catch
               return false

         if (A_Index == 1) {
            pBitmap1 := this.toBitmap(type, image)
            type1 := type
         } else {
            pBitmap2 := this.toBitmap(type, image)
            result := this.isBitmapEqual(pBitmap1, pBitmap2)
            this.toDispose(type, pBitmap2)
            if (result)
               continue
            else
               return false
         }
      }

      this.toDispose(type1, pBitmap1)

      this.gdiplusShutdown()

      return true
   }

   isBitmapEqual(ByRef pBitmap1, ByRef pBitmap2, Format := 0x26200A) {
      ; Make sure both bitmaps are valid pointers.
      if !(pBitmap1 && pBitmap2)
         return false

      ; Check if pointers are identical.
      if (pBitmap1 == pBitmap2)
         return true

      ; The two bitmaps must be the same size.
      DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap1, "uint*", Width1)
      DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap2, "uint*", Width2)
      DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap1, "uint*", Height1)
      DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap2, "uint*", Height2)

      ; Match bitmap dimensions.
      if (Width1 != Width2 || Height1 != Height2)
         return false

      ; Create a RECT with the width and height and two empty BitmapData.
      VarSetCapacity(Rect, 16, 0)                    ; sizeof(Rect) = 16
         , NumPut(  Width1, Rect,  8,   "uint")      ; Width
         , NumPut( Height1, Rect, 12,   "uint")      ; Height
      VarSetCapacity(BitmapData1, 16+2*A_PtrSize, 0) ; sizeof(BitmapData) = 24, 32
      VarSetCapacity(BitmapData2, 16+2*A_PtrSize, 0) ; sizeof(BitmapData) = 24, 32

      ; Transfer the pixels to a read-only buffer. Avoid using a different PixelFormat.
      DllCall("gdiplus\GdipBitmapLockBits"
               ,    "ptr", pBitmap1
               ,    "ptr", &Rect
               ,   "uint", 1            ; ImageLockMode.ReadOnly
               ,    "int", Format       ; Format32bppArgb is fast.
               ,    "ptr", &BitmapData1)
      DllCall("gdiplus\GdipBitmapLockBits"
               ,    "ptr", pBitmap2
               ,    "ptr", &Rect
               ,   "uint", 1            ; ImageLockMode.ReadOnly
               ,    "int", Format       ; Format32bppArgb is fast.
               ,    "ptr", &BitmapData2)

      ; Get Stride (number of bytes per horizontal line) and two pointers.
      Stride := NumGet(BitmapData1,  8, "int")
      Scan01 := NumGet(BitmapData1, 16, "ptr")
      Scan02 := NumGet(BitmapData2, 16, "ptr")

      ; RtlCompareMemory preforms an unsafe comparison stopping at the first different byte.
      size := Stride * Height1
      byte := DllCall("ntdll\RtlCompareMemory", "ptr", Scan01+0, "ptr", Scan02+0, "uptr", size, "uptr")

      ; Cleanup
      DllCall("gdiplus\GdipBitmapUnlockBits", "ptr", pBitmap1, "ptr", &BitmapData1)
      DllCall("gdiplus\GdipBitmapUnlockBits", "ptr", pBitmap2, "ptr", &BitmapData2)
      return (byte == size) ? true : false
   }
} ; End of ImageEqual class.
