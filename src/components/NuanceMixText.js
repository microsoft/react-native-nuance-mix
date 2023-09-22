/*****
  This is a React Native component named NuanceMixText which provides a text-to-speech interface to the Nuance Mix TTS API. 
  The component imports React, PropTypes, View, Text, NativeModules, and NativeEventEmitter from the react-native library. 
  It takes some props such as style, viewStyle, children, voice, language, model, and ssml. The component sets default props for voice, language, model, and ssml. 
  Within the component, there is a state hook for isPlaying which is a boolean that determines whether the component is currently playing speech. 
  It defines an event handler for handlePlaybackDone which is used by the Nuance Mix TTS API. The playTts function is used to handle the text-to-speech functionality. 
  Finally, the component returns a View containing a Text component that is synthesized to speech by pressing it.
*****/ 
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from "react";
import { View, Text, NativeModules, NativeEventEmitter } from "react-native";
import PropTypes from "prop-types";

// This component provides a text-to-speech interface to the Nuance Mix TTS API.
const NuanceMixText = ({
  style,
  viewStyle,
  children,
  voice,
  language,
  model,
  ssml,
  TTS,
  ...rest
}) => {

  const [isPlaying, setIsPlaying] = React.useState(false);

  const NuanceMix = NativeModules.NuanceMix
  const myModuleEvt = new NativeEventEmitter(NativeModules.NuanceMix)
  NuanceMix.init("tts");

  // Event handlers for the Nuance Mix TTS API.
  function handlePlaybackDone() {
    console.log('handlePlaybackDone ' + isPlaying);
    setIsPlaying(false);
    myModuleEvt.removeAllListeners('NuanceMixPlaybackDone');
  }
  const playTts = () => {
    setIsPlaying(true);
    myModuleEvt.addListener('NuanceMixPlaybackDone', handlePlaybackDone);  
    NuanceMix.synthesize(children, ssml, voice, language, model)
  };

  // Return a View containing a Text component that is synthesized to speech by pressing it.
  return (
    <View style={viewStyle}
      {...rest}
    >
      {TTS ? <TTS style={style} playTts={playTts} children={children} {...rest} /> : 
              <DefaultTTS style={style} playTts={playTts} children={children} {...rest} />}
    </View>
  );
};

function DefaultTTS({ style, playTts, children, ...rest }) {
  return (
    <Text style={style}
      onPress={playTts}
      {...rest}
    >{children}
    </Text>
  );
};

NuanceMixText.defaultProps = {
  voice: "not-specified",
  language: "en-us",
  model: "enhanced",
  ssml: null,
  TTS: DefaultTTS,
};

NuanceMixText.propTypes = {
  children: PropTypes.node,
  voice: PropTypes.string,
  language: PropTypes.string,
  model: PropTypes.string,
  ssml: PropTypes.string,
  TTS: PropTypes.func,
};

export default NuanceMixText;
