#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"
#include "ofxAssimpModelLoader.h"

// BGG rtcmix stuff
extern "C" {
    int rtcmixmain();
    int maxmsp_rtsetparams(float sr, int nchans, int vecsize, float *mm_inbuf, float *mm_outbuf);
    void pullTraverse(short *inbuf, short *outbuf);
    int parse_score(char *thebuf, int buflen);
    int check_bang();
    char *get_print();
    void reset_print();
}

class ofApp : public ofxiOSApp {
	
    public:
        void setup();
        void update();
        void draw();
        void exit();
	
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);
    
        void updateRonaldAppearance();
    
        void parseRTInput(char *filename);
        void doChorus(char *samplename, int nvoices, float outdur, float trans, float amp);

    // 3D model stuff
    ofxAssimpModelLoader ronaldModel;
    
    // touching
    bool isTouchDown;
    float lastTouchX;
    float lastTouchY;
    
    float currentRotationY;
    
    int currentTouchesDown;
    int currentGB;
    float currentScale;
    float xBodyOffset;
    float yBodyOffset;

    unsigned long frameCount;
    unsigned long lastChoralFrame;
    
    // BGG audio stuff
    void audioRequested(float * output, int bufferSize, int nChannels);
    short *s_audio_outbuf; // this is the buf filled by rtcmix (it uses short samples)
    int nchans;
    int framesize;
};


