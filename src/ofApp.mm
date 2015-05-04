#include "ofApp.h"

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
    lastChoralFrame = 0;
    
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
        double rand = ((double)arc4random() / 0x100000000);
        printf("rand: %f\n", rand);
        xBodyOffset += (0.5 - rand) * 3;
        if (xBodyOffset < -40) {
            xBodyOffset = -40;
        } else if (xBodyOffset > 40) {
            xBodyOffset = 40;
        }
        
        rand = ((double)arc4random() / 0x100000000);
        yBodyOffset += (0.5 - rand) * 3;
        if (yBodyOffset < -40) {
            yBodyOffset = -40;
        } else if (yBodyOffset > 40) {
            yBodyOffset = 40;
        }
        
        printf("%f %f\n", xBodyOffset, yBodyOffset);
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
        
        currentTouchesDown = MIN(currentTouchesDown + 1, 255);
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
    float percent = (currentTouchesDown / 255.0f);
    
    currentGB = 255 - currentTouchesDown;
    
    currentScale = (percent * 2) + 2;
    
    if (frameCount - lastChoralFrame > 60) {
        int nvoices = 1 + (percent * 45);
        printf("doing it with voices %d\n", nvoices);
        doChorus("ouch.aiff", nvoices);
        lastChoralFrame = frameCount;
    }
}

void ofApp::parseRTInput(char *filename) {
    char rtinputScore[1024];
    sprintf(rtinputScore, "rtinput(\"%s%s\")", ofToDataPath("").c_str(), filename);
    parse_score(rtinputScore, strlen(rtinputScore));
}

void ofApp::doChorus(char *samplename, int nvoices) {
    
    // JCHOR(outsk, insk, dur, indur, inmaintain, pitch, nvoices, MINAMP, MAXAMP, MINWAIT, MAXWAIT, seed, inputchan, AMPENV, GRAINENV)
    char *scoreTemplate = { "\
        inchan = 0 \
        inskip = 0.0 \
        \
        outdur = 2 \
        \
        indur = 0.4 \
        maintain_dur = 1 \
        transposition = 0.07 \
        nvoices = %d \
        minamp = 0.01 \
        maxamp = 1.0 \
        minwait = 0.00 \
        maxwait = 0.30 \
        seed = 0.9371 \
        \
        amp = 0.5 \
        env = maketable(\"line\", 1000, 0,0, 1,1, outdur-1,1, outdur,0) \
        \
        grainenv = maketable(\"window\", 1000, \"hanning\") \
        \
        JCHOR(0, inskip, outdur, indur, maintain_dur, transposition, nvoices, minamp, maxamp, minwait, maxwait, seed, inchan, amp * env, grainenv) \
        "};
    
    parseRTInput(samplename);
    
    char score[2048];
    sprintf(score, scoreTemplate, nvoices);
    
    parse_score(score, strlen(score));
}

