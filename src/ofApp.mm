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
    ronaldModel.setScale(2, 2, 2);
    
    isTouchDown = NO;
    lastTouchX = 0;
    lastTouchY = 0;
    
    currentRotationY = 0;
    
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

}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(0, 0, 0, 255);
    ofSetColor(255, 255, 255, 255);
    
    ronaldModel.setPosition(ofGetWidth()/2, (float)ofGetHeight() * 0.5 , 0);
    ronaldModel.drawFaces();
}

//--------------------------------------------------------------
void ofApp::exit(){

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    isTouchDown = true;
    
    parseRTInput("ouch.aiff");
    
    // JCHOR(outsk, insk, dur, indur, inmaintain, pitch, nvoices, MINAMP, MAXAMP, MINWAIT, MAXWAIT, seed, inputchan, AMPENV, GRAINENV)
    char *score = { "\
        inchan = 0 \
        inskip = 0.0 \
        \
        outdur = 2 \
        \
        indur = 0.4 \
        maintain_dur = 1 \
        transposition = 0.07 \
        nvoices = 5 \
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
    parse_score(score, strlen(score));
    
    lastTouchX = touch.x;
    lastTouchY = touch.y;
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    if (isTouchDown) {
        float dx = touch.x - lastTouchX;
        
        currentRotationY -= dx * 0.75;
        
        ronaldModel.setRotation(0, currentRotationY, 0, 1, 0);
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

void ofApp::parseRTInput(char *filename) {
    char rtinputScore[1024];
    sprintf(rtinputScore, "rtinput(\"%s%s\")", ofToDataPath("").c_str(), filename);
    parse_score(rtinputScore, strlen(rtinputScore));
}

