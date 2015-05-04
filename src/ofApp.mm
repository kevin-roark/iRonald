#include "ofApp.h"

const int MAX_TOUCH_COUNT = 375;

double rfloat() {
    return ((double)arc4random() / 0x100000000);
}

//--------------------------------------------------------------
void ofApp::setup(){
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
        currentTouchesDown = currentTouchesDown - 1;
        updateRonaldAppearance();
    }
    
    frameCount += 1;
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(0, 0, 0, 255);
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
    }
    
    lastTouchX = touch.x;
    lastTouchY = touch.y;
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    isTouchDown = false;
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
    
    currentScale = (percent * 3) + 2;
    
    if (frameCount - lastChoralFrame > 90) {
        int nvoices = 1 + (percent * 60);
        float dur = 2 + (percent * 4 * max(0.25, rfloat()));
        float amp = 0.35 + (percent * 0.275);
        
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
        doChorus("ouch.aiff", nvoices, dur, trans, amp);
        lastChoralFrame = frameCount;
    }
}

void ofApp::parseRTInput(char *filename) {
    char rtinputScore[1024];
    sprintf(rtinputScore, "rtinput(\"%s%s\")", ofToDataPath("").c_str(), filename);
    parse_score(rtinputScore, strlen(rtinputScore));
}

void ofApp::doChorus(char *samplename, int nvoices, float outdur, float trans, float amp) {
    
    // JCHOR(outsk, insk, dur, indur, inmaintain, pitch, nvoices, MINAMP, MAXAMP, MINWAIT, MAXWAIT, seed, inputchan, AMPENV, GRAINENV)
    char *scoreTemplate = { "\
        inchan = 0 \
        inskip = 0.0 \
        \
        outdur = %.2f \
        \
        indur = 0.4 \
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
    sprintf(score, scoreTemplate, outdur, trans, nvoices, amp);
    
    parse_score(score, strlen(score));
}
