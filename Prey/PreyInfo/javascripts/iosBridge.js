/**
 * iosBridge.js
 *
 * iosBridge.js is javascript bridge iOS webview
 *
 * Created by Javier Cala Uribe on 13/2/18.
 * Copyright © 2018 Fork Ltd. All rights reserved.

 *
 * Released under the MIT and GPL Licenses.
 *
 * ------------------------------------------------
 *  author:  Javier Cala Uribe
 *  version: 0.1.0
 *  source:  http://github.com/prey/prey-ios-client/
 */
/*
$(function(){
  
  
  
});*/

function checkTouchIDiOS() {
    var url = 'ioschecktouchid://';
    openCustomURLinIFrame(url);
}

function checkAuthiOS() {
    var url = 'ioscheckauth://';
    openCustomURLinIFrame(url);
}

function checkPasswordiOS() {
    var url = 'iossettings://'+document.getElementById('lpass').value;
    openCustomURLinIFrame(url);
}

function openCustomURLinIFrame(src) {
    var rootElm = document.documentElement;
    var newFrameElm = document.createElement("IFRAME");
    newFrameElm.setAttribute("src",src);
    rootElm.appendChild(newFrameElm);
    //remove the frame now
    newFrameElm.parentNode.removeChild(newFrameElm);
}
