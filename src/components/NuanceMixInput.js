/*****
  This is a React Native component named NuanceMixInput which provides a text input interface to the Nuance Mix ASR (Automated Speech Recognition) API. 
  The component imports React, PropTypes, View, TextInput, NativeModules, and NativeEventEmitter from the react-native library. 
  It has some props such as style, component, initialText, and language. It also sets default props for initialText and language. 
  Within the component, there are state hooks for value(which is the input value), and isRecording (which is a boolean that determines whether the component is currently recording). 
  It also defines event handlers for handleResult and handleRecordingDone, which are used by the Nuance Mix ASR API. The recognize function begins the recognition process and sets up the event listeners. 
  Finally, the component returns a View with a TextInput and a component that is defined by the component prop (usually a button) that triggers the recognize function when pressed.
*****/
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from "react";
import { View, TextInput, NativeModules, NativeEventEmitter } from "react-native";
import PropTypes from "prop-types";

// This component provides a text input interface to the Nuance Mix ASR API.
const NuanceMixInput = ({
  style,
  viewStyle,
  Listener,
  Input,
  initialText,
  language,
  ...rest
}) => {

  const [value, onChangeText] = React.useState(initialText);
  const [isRecording, setIsRecording] = React.useState(false);

  const NuanceMix = NativeModules.NuanceMix
  const myModuleEvt = new NativeEventEmitter(NativeModules.NuanceMix)
  NuanceMix.init("asr");

  // Event handlers for the Nuance Mix ASR API.
  function handleResult(result) {
    console.log("handleResult " + result);
    onChangeText(result);
  };
  function handleRecordingDone() {
    console.log("handleRecordingDone " + isRecording);
    setIsRecording(false);
    myModuleEvt.removeAllListeners('NuanceMixRecognitionResult');
    myModuleEvt.removeAllListeners('NuanceMixRecordingDone');
  };
  const recognize = () => {
    setIsRecording(true);
    console.log('recognizing .....');
    myModuleEvt.addListener('NuanceMixRecognitionResult', handleResult);
    myModuleEvt.addListener('NuanceMixRecordingDone', handleRecordingDone);
    NuanceMix.recognize(language);
  };

  // Return
  return (
    <View style={viewStyle}>
      {Input ? <Input style={style} {...rest} value={value} onChangeText={(text) => onChangeText(text)} /> : 
              <DefaultInput style={style} {...rest} value={value} onChangeText={(text) => onChangeText(text)} />}
      {React.cloneElement(Listener, {onPress:recognize})}
    </View>
  );
};

function DefaultInput({ style, value, onChangeText }) {
  return (
    <TextInput
      style={style}
      value={value}
      onChangeText={(text) => onChangeText(text)}
    />
  )
}

NuanceMixInput.defaultProps = {
  initialText: "",
  language: null,
  Input: DefaultInput,
}

NuanceMixInput.propTypes = {
  viewStyle: PropTypes.object,
  initialText: PropTypes.string,
  Listener: PropTypes.object.isRequired,
  Input: PropTypes.func,
  language: PropTypes.string,
};

export default NuanceMixInput;
