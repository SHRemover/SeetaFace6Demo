//
//  ViewController.m
//  SeetaFace6Demo
//
//  Created by SH on 2021/3/11.
//

#import "ViewController.h"

#include <SeetaFaceDetector600/seeta/FaceDetector.h>
#include <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
#include <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
#include <SeetaFaceTracking600/seeta/FaceTracker.h>

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgcodecs/ios.h>

#include <iostream>
#include <fstream>

@interface ViewController ()

@end

@implementation ViewController

/*** SeetaImageData */
namespace seeta
{
    namespace cv
    {
    // using namespace ::cv;
    class ImageData : public SeetaImageData {
    public:
        ImageData( const ::cv::Mat &mat )
        : cv_mat( mat.clone() ) {
            this->width = cv_mat.cols;
            this->height = cv_mat.rows;
            this->channels = cv_mat.channels();
            this->data = cv_mat.data;
        }
    private:
        ::cv::Mat cv_mat;
    };
    }
}


// 提取图片特征值
std::shared_ptr<float> extract_img(seeta::FaceDetector *fd,
                                   seeta::FaceRecognizer *fr,
                                   seeta::FaceLandmarker *fl,
                                   std::string imgPath) {
    
    seeta::cv::ImageData imgData = cv::imread(imgPath);
        
    auto faces = fd->detect_v2(imgData);
    
    auto points1 = fl->mark(imgData, faces[0].pos);
    
    std::shared_ptr<float> features(new float[fr->GetExtractFeatureSize()],
                                    std::default_delete<float[]>());
    
    fr->Extract(imgData, points1.data(), features.get());
    
    return features;
}

// 提取图片特征值
std::vector<std::shared_ptr<float>> extract_img1(seeta::FaceDetector *fd,
                                                 seeta::FaceRecognizer *fr,
                                                 seeta::FaceLandmarker *fl,
                                                 std::string imgPath) {
    
    std::vector<std::shared_ptr<float>> features;
    
    seeta::cv::ImageData imgData = cv::imread(imgPath);
    
    std::vector<SeetaFaceInfo> faces = fd->detect_v2(imgData);
    
    std::cout << "faces count " << faces.size() << std::endl;
    
    std::vector<SeetaFaceInfo> ::const_iterator cit = faces.begin();
    
    while(cit != faces.end()){
        
        SeetaFaceInfo faceInfo = *cit;
        
        auto points = fl->mark(imgData, faceInfo.pos);
        
        std::shared_ptr<float> feature(new float[fr->GetExtractFeatureSize()],
                                       std::default_delete<float[]>());
        
        fr->Extract(imgData, points.data(), feature.get());
        
        features.push_back(feature);
        
        cit++;
    }
    
    return features;
}


/*** 特征值对比 */
float compare(seeta::FaceRecognizer *fr,
              const std::shared_ptr<float> &feat1,
              const std::shared_ptr<float> &feat2) {
    return fr->CalculateSimilarity(feat1.get(), feat2.get());
}

float compare(const float *lhs, const float *rhs, int size) {
    float sum = 0;
    for (int i = 0; i < size; ++i) {
        sum += *lhs * *rhs;
        ++lhs;
        ++rhs;
    }
    return sum;
}

float compareFixFeature(NSArray<NSString *> *feature, const float *rhs, int size) {
    float sum = 0;
    for (int i = 0; i < size; ++i) {
        CGFloat fl1 = feature[i].floatValue;
        sum += fl1 * *rhs;
        ++rhs;
    }
    return sum;
}

- (CGFloat)compareFeature1:(NSArray<NSString *> *)feature1 feature2:(NSArray<NSString *> *)feature2 {
    CGFloat sum = 0;
    for (int i = 0; i < feature1.count; i ++) {
        CGFloat fl1 = feature1[i].floatValue;
        CGFloat fl2 = feature2[i].floatValue;
        sum += fl1 * fl2;
    }
    return sum;
}

std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];
seeta::ModelSetting FD_model(buddle + "/assert/model/face_detector.csta");
seeta::ModelSetting FR_model(buddle + "/assert/model/face_recognizer.csta");
seeta::ModelSetting FL_model(buddle + "/assert/model/face_landmarker_pts5.csta");


- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor cyanColor];
    btn.frame = CGRectMake(100, 108, 100, 100);
    [btn addTarget:self action:@selector(btnAction) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self.view addSubview:btn];
}


- (void)btnAction {
    
    [self getImgFeature];
    
    [self printImgFeature];
    
    [self compare1];
    
    [self compare2];
}

/*** 提取特征值 */
- (void)getImgFeature {
    
    seeta::FaceDetector FD(FD_model);
    seeta::FaceLandmarker FL(FL_model);
    seeta::FaceRecognizer FR(FR_model);
    
    std::vector<std::string> imgPathArr;
    for (int i = 0; i < 5; i ++) {
        std::string path = buddle + "/assert/image/" + std::to_string(i+1) + ".JPG";
        imgPathArr.push_back(path);
    }
    
    int x = 0;
    std::vector<std::string>::iterator imgPath;
    for (imgPath = imgPathArr.begin(); imgPath != imgPathArr.end(); imgPath ++) {

        std::cout << "img_index *** " << x << std::endl;

        std::vector<std::shared_ptr<float>> valueArr = extract_img1(&FD, &FR, &FL, *imgPath);

        std::vector<std::shared_ptr<float>>::iterator feature;
        for (feature = valueArr.begin(); feature != valueArr.end(); feature ++) {

            std::cout << "Feature Adress " << *feature << std::endl;
            std::cout << "Feature Value " << **feature << std::endl;
        }

        x ++;
    }
}


/*** 提取特征值 & 输出 Feature float 数组 */
- (void)printImgFeature {
    
    seeta::FaceDetector FD(FD_model);
    seeta::FaceLandmarker FL(FL_model);
    seeta::FaceRecognizer FR(FR_model);
    
    std::string imgPath = buddle + "/assert/image/11.JPG";
    
    std::shared_ptr<float> feature = extract_img(&FD, &FR, &FL, imgPath);
    float *rhs = feature.get();
    
    for (int i = 0; i < 1024; ++i) {
        float value = *rhs;
        std::cout << i << " * Value * " << value << std::endl;
        ++rhs;
    }
    
}


/*** 本地人脸识别&比对 */
- (void)compare1 {
    
    seeta::FaceDetector FD(FD_model);
    seeta::FaceLandmarker FL(FL_model);
    seeta::FaceRecognizer FR(FR_model);
    
    std::vector<std::string> imgPathArr;
    for (int i = 0; i < 5; i ++) {
        std::string path = buddle + "/assert/image/" + std::to_string(i+11) + ".JPG";
        imgPathArr.push_back(path);
    }
    
    std::vector<std::shared_ptr<float>> valueArr;
    std::vector<std::string>::iterator imgPath;
    for (imgPath = imgPathArr.begin(); imgPath != imgPathArr.end(); imgPath ++) {
        std::shared_ptr<float> value = extract_img(&FD, &FR, &FL, *imgPath);
        valueArr.push_back(value);
    }
    
    int x = 0;
    std::vector<std::shared_ptr<float>>::iterator value_i;
    for (value_i = valueArr.begin(); value_i != valueArr.end(); value_i ++) {

        std::cout << "img_index *** " << x << std::endl;
        std::cout << "Feature Adress " << *value_i << std::endl;
        std::cout << "Feature Value " << **value_i << std::endl;
//        std::cout << "Feature Value " << *value_i->get() << std::endl;

        int y = 0;
        std::vector<std::shared_ptr<float>>::iterator value_j;
        for (value_j = valueArr.begin(); value_j != valueArr.end(); value_j ++) {

            float com = compare(&FR, *value_i, *value_j);

            std::cout << "compare: " << x << "_" << y << " * value: " << com << std::endl;

            y ++;
        }
        x ++;
    }
}

/*** 后台特征值接收 与 本地图片人脸识别比对 */
- (void)compare2 {
    
    seeta::FaceDetector FD(FD_model);
    seeta::FaceLandmarker FL(FL_model);
    seeta::FaceRecognizer FR(FR_model);
    
    std::string imgPath = buddle + "/assert/image/11.JPG";
    std::string imgPath2 = buddle + "/assert/image/13.JPG";
    
    // 模仿后台数据 - 特征值字符串
    NSMutableString *resultStr = [NSMutableString string];
    std::shared_ptr<float> feature = extract_img(&FD, &FR, &FL, imgPath);
    float *rhs = feature.get();
    
    for (int i = 0; i < 1024; ++i) {
        float value = *rhs;
        
        NSString *valueStr = [NSString stringWithFormat:@"%f,", value];
        [resultStr appendString:valueStr];
    
        ++rhs;
    }
    
//    NSLog(@"resultStr: %@", resultStr);

    NSArray *featureArr = [resultStr componentsSeparatedByString:@","];
    std::shared_ptr<float> feature2 = extract_img(&FD, &FR, &FL, imgPath2);
    
    float com = compareFixFeature(featureArr, feature2.get(), 1024);
    
    std::cout << "compare: " << com << std::endl;
}


/***
 
//// * 构造人脸识别器
//seeta::FaceRecognizer *new_fr() {
//    seeta::ModelSetting setting;
//    setting.append("face_recognizer.csta");
//    return new seeta::FaceRecognizer(setting);
//}

//// * 提取特征值
//// 特征提取过程可以分为两个步骤：1. 根据人脸5个关键点裁剪出人脸区域；2. 将人脸区域输入特征提取网络提取特征。
////
//// Extract方法一次完成两个步骤的工作。
//std::shared_ptr<float> extract(seeta::FaceRecognizer *fr,
//                               const SeetaImageData &image,
//                               const std::vector<SeetaPointF> &points) {
//    std::shared_ptr<float> features(new float[fr->GetExtractFeatureSize()],
//                                    std::default_delete<float[]>());
//    fr->Extract(image, points.data(), features.get());
//    return features;
//}

//// 分步骤的特征提取方式
//std::shared_ptr<float> extract_v2(seeta::FaceRecognizer *fr,
//                                  const SeetaImageData &image,
//                                  const std::vector<SeetaPointF> &points) {
//    std::shared_ptr<float> features(new float[fr->GetExtractFeatureSize()],
//                                    std::default_delete<float[]>());
//    seeta::ImageData face = fr->CropFaceV2(image, points.data());
//    fr->ExtractCroppedFace(face, features.get());
//    return features;
//}

//- (void)config {
//    std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];
//
//    // 可将 face_recognizer.csta 上传至服务器 动态加载
//    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *facepath = [NSString stringWithFormat:@"%@/%@", path, @"face_recognizer.csta"];
//    NSLog(@"facepath: %@", facepath);
//
//    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%s%s", buddle.c_str(), "/assert/model/face_recognizer.csta"]];
//    [data writeToFile:facepath atomically:YES];
//
//    std::string pathStr = [facepath UTF8String];
//    seeta::ModelSetting FR_model(pathStr);
//
//    NSLog(@"data: %lu", (unsigned long)data.length);
//
//    seeta::ModelSetting FD_model(buddle + "/assert/model/face_detector.csta");
//    seeta::ModelSetting FL_model(buddle + "/assert/model/face_landmarker_pts5.csta");
//    seeta::ModelSetting FR_model(buddle + "/assert/model/face_recognizer.csta");
//
//    seeta::FaceDetector FD(FD_model);
//    seeta::FaceLandmarker FL(FL_model);
//    seeta::FaceRecognizer FR(FR_model);
//}


//// 分割字符串
//std::vector<std::string> split(const std::string& str, const std::string& pattern) {
//
//    std::vector<std::string> ret;
//    if(pattern.empty()) return ret;
//
//    size_t start=0,index=str.find_first_of(pattern,0);
//    while(index!=str.npos) {
//        if(start!=index) {
//            ret.push_back(str.substr(start,index-start));
//        }
//        start=index+1;
//        index=str.find_first_of(pattern,start);
//    }
//    if(!str.substr(start).empty()){
//        ret.push_back(str.substr(start));
//    }
//    return ret;
//}


 */

@end
