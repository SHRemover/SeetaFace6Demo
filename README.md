# SeetaFace6Demo

[SeetaFace6](https://github.com/seetafaceengine/SeetaFace6)

SeetaFace6 简化版、 iOS端 人脸识别&amp;比对

1. SDK 依赖 Accelerate.framework，直接添加系统版本即可。
2. framework 中链接的全部为动态库，因此：
   a. 需要设置 TARGETS/General/Frameworks 中的选项里的 Embed 字段为 `Embed&Sign`。
   b. 需要设置 TARGETS/Build Phases/Copy Bundle Resources 将Seeta SDK 中的所有framework添加进去。
   c. 动态库没有打开bitcode支持，需要设置 TRAGETS/Build Settings/Build Options/Enable Bitcode 为 No。
3. SDK 最低支持IOS 9.0。
4. 引用头文件时，区别于其他平台，需要加上framework的路径，或者其他方式声明好的头文件路径。
   例如，如果将framework都拷贝到工程路径，头文件包含路径应写成类似：
       #include <SeetaFaceDetector600/seeta/FaceDetector.h>
       #include <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
       #include <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
       #include <SeetaFaceAntiSpoofingX600/seeta/FaceAntiSpoofing.h>
5. 当前提供的为IOS硬件运行版本，模拟器环境不能运行。
6. 打包中没有提供模型文件，模型文件与其他平台共享。
7. SDK 的接口特性和说明，参照其他平台说明文档。
8. opencv2.framework & SeetaFace6 模型文件过大未上传，需自行下载导入。
