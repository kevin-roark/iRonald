#include "ofApp.h"

const int MAX_TOUCH_COUNT = 500;

double rfloat() {
    return ((double)arc4random() / 0x100000000);
}

//--------------------------------------------------------------
void ofApp::setup(){
    printf("window size %d %d\n", ofGetWidth(), ofGetHeight());
    
    // BGG audio stuff
    int sr = 44100;
    int nbufs = 2; // you can use more for more processing but latency will suffer
    
    nchans = 2;
    framesize = 512;
    
    s_audio_outbuf = (short*)malloc(nchans*framesize*sizeof(short));
    
    // 3D stuff
    ronaldModel.loadModel("low_poly_male.3ds");
    
    isTouchDown = NO;
    lastTouchX = 0;
    lastTouchY = 0;
    
    currentRotationY = 0;
    
    currentTouchesDown = 0;
    currentGB = 255;
    currentScale = 2;
    xBodyOffset = 0;
    yBodyOffset = 0;

    frameCount = 0;
    lastChoralFrame = -100;
    
    // initialize RTcmix
	rtcmixmain();
	maxmsp_rtsetparams(sr, nchans, framesize, NULL, NULL);
    
    ofSoundStreamSetup(nchans, 0, sr, framesize, nbufs);
    ofSoundStreamStart();
    
    char *setupScore = { " \
        load(\"JCHOR\") \
        wave = maketable(\"wave\", 1000, \"sine\") \
        amp = 20000 \
        ampenv = maketable(\"line\", 1000, 0,0, 5,1, 10,0) \
        "};
    parse_score(setupScore, strlen(setupScore));
}

void ofApp::audioRequested(float * output, int bufferSize, int nChannels) {
    pullTraverse(NULL, s_audio_outbuf);
    
    for (int i = 0; i < framesize*nchans; i++)
        output[i] = (float)s_audio_outbuf[i]/32786.0; // transfer to the float *output buf
    
    
    if (check_bang() == 1) {
    }
    
    char *pbuf = get_print();
    char *pbufptr = pbuf;
    while (strlen(pbufptr) > 0) {
        ofLog() << pbufptr;
        pbufptr += (strlen(pbufptr) + 1);
    }
    reset_print();
}


//--------------------------------------------------------------
void ofApp::update(){
    if (!isTouchDown && currentTouchesDown > 0) {
        currentTouchesDown = MAX(0, currentTouchesDown - 3);
        updateRonaldAppearance();
    }
    
    frameCount += 1;
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(195, 195, 195, 255);
    ofSetColor(255, currentGB, currentGB, 255);
    
    if (isTouchDown) {
        xBodyOffset += (0.5 - rfloat()) * 3;
        if (xBodyOffset < -40) {
            xBodyOffset = -40;
        } else if (xBodyOffset > 40) {
            xBodyOffset = 40;
        }
        
        yBodyOffset += (0.5 - rfloat()) * 3;
        if (yBodyOffset < -40) {
            yBodyOffset = -40;
        } else if (yBodyOffset > 40) {
            yBodyOffset = 40;
        }
    }
    
    ronaldModel.setScale(currentScale, currentScale, currentScale);
    ronaldModel.setPosition(ofGetWidth()/2 + xBodyOffset, (float)ofGetHeight() * 0.5 + yBodyOffset, 0);
    ronaldModel.drawFaces();
}

//--------------------------------------------------------------
void ofApp::exit(){

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    isTouchDown = true;
    
    lastTouchX = touch.x;
    lastTouchY = touch.y;
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    if (isTouchDown) {
        float dx = touch.x - lastTouchX;
        
        currentRotationY -= dx * 0.75;
        if (currentRotationY < -90) {
            currentRotationY = -90;
        }
        else if (currentRotationY > 90) {
            currentRotationY = 90;
        }
        
        ronaldModel.setRotation(0, currentRotationY, 0, 1, 0);
        
        currentTouchesDown = MIN(currentTouchesDown + 1, MAX_TOUCH_COUNT);
        updateRonaldAppearance();
        
        
        if (frameCount - lastChoralFrame > 70) {
            oinkChorus(touch.x, touch.y);
            lastChoralFrame = frameCount;
        }
    }
    
    lastTouchX = touch.x;
    lastTouchY = touch.y;
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    isTouchDown = false;
    
    float percent = (currentTouchesDown / (float)MAX_TOUCH_COUNT);
    float dur = percent * 12 + 5;
    addGVerb(dur);
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}


/// kev's helpers

void ofApp::updateRonaldAppearance() {
    float percent = (currentTouchesDown / (float)MAX_TOUCH_COUNT);

    currentGB =  (1 - percent) * 255;
    
    currentScale = (percent * 4) + 2;
}

void ofApp::oinkChorus(int touchX, int touchY) {
    float percent = (currentTouchesDown / (float)MAX_TOUCH_COUNT);
    
    int nvoices = 1 + (percent * 50);
    float dur = 2 + (percent * 3.5);
    float amp = 0.4 + (percent * 0.21);
    
    float trans = 0;
    float p = rfloat();
    if (p < 0.2) {
        trans = rfloat() * -0.3 - 0.05;
    } else if (p < 0.4) {
        trans = rfloat() * 0.3 + 0.05;
    } else if (p < 0.6) {
        trans = rfloat() * -0.12 - 0.01;
    } else if (p < 0.8) {
        trans = rfloat() * 0.12 + 0.01;
    } else {
        trans = rfloat() * 0.05;
    }
    
    printf("doing it with voices %d dur %f trans %f amp %f\n", nvoices, dur, trans, amp);
    
    if (touchY < 0.29 * ofGetHeight()) {
        printf("head\n");
        doChorus("i_ronald.aiff", 0.68, nvoices, dur, trans, amp);
    }
    else if (touchY < 0.56 * ofGetHeight()) {
        if (touchX < ofGetWidth() / 3) {
            printf("left arm\n");
            doChorus("eeee.aiff", 0.62, nvoices, dur, trans, amp);
        }
        else if (touchX > ofGetWidth() * 0.67) {
            printf("right arm\n");
            doChorus("dont_touch.aiff", 1.1, nvoices, dur, trans, amp);
        }
        else {
            printf("tummy\n");
            doChorus("ouch.aiff", 0.4, nvoices, dur, trans, amp);
        }
    }
    else {
        if (touchX < ofGetWidth() / 2) {
            printf("left leg\n");
            doChorus("haha.aiff", 0.64, nvoices, dur, trans, amp);
        }
        else {
            printf("right leg\n");
            doChorus("stop.aiff", 0.8, nvoices, dur, trans, amp);
        }
    }
}

void ofApp::parseRTInput(char *filename) {
    char rtinputScore[1024];
    sprintf(rtinputScore, "rtinput(\"%s%s\")", ofToDataPath("").c_str(), filename);
    parse_score(rtinputScore, strlen(rtinputScore));
}

void ofApp::doChorus(char *samplename, float indur, int nvoices, float outdur, float trans, float amp) {
    
    // JCHOR(outsk, insk, dur, indur, inmaintain, pitch, nvoices, MINAMP, MAXAMP, MINWAIT, MAXWAIT, seed, inputchan, AMPENV, GRAINENV)
    char *scoreTemplate = { "\
        inchan = 0 \
        inskip = 0.0 \
        \
        outdur = %.2f \
        \
        indur = %.2f \
        maintain_dur = 1 \
        transposition = %.3f \
        nvoices = %d \
        minamp = 0.01 \
        maxamp = 1.0 \
        minwait = 0.00 \
        maxwait = 0.30 \
        seed = 0.9371 \
        \
        amp = %.3f \
        env = maketable(\"line\", 1000, 0,0, 1,1, outdur-1,1, outdur,0) \
        \
        grainenv = maketable(\"window\", 1000, \"hanning\") \
        \
        JCHOR(0, inskip, outdur, indur, maintain_dur, transposition, nvoices, minamp, maxamp, minwait, maxwait, seed, inchan, amp * env, grainenv) \
        "};
    
    parseRTInput(samplename);
    
    char score[4096];
    sprintf(score, scoreTemplate,outdur, indur, trans, nvoices, amp);
    
    parse_score(score, strlen(score));
}

void ofApp::addGVerb(float dur) {
    // GVERB(outsk, insk, dur, AMP, ROOMSIZE, RVBTIME, DAMPING, BANDWIDTH, DRYLEVEL, EARLYREFLECT, RVBTAIL, RINGDOWN[, INCHAN])
    char *scoreTemplate = "GVERB(0, 0, %f, 0.5, 150.0, 10.0, 0.71, 0.34, -10.0, -11.0, -9.0, 7.0)";
    
    char score[1024];
    sprintf(score, scoreTemplate, dur);
    
    parse_score(score, strlen(score));
}
