/*****
  This is a React Native component named NuanceMixChat which provides a chat interface to the Nuance Mix Dialog API. The component imports React, PropTypes, View, TextInput, Text, StyleSheet, FlatList, NativeModules, NativeEventEmitter, and FontAwesomeIcon from the react-native and react-native-vector-icons libraries. 
  It has some props such as style, viewStyle, FooterInput, FooterListener, FooterProgress, LeftBubble, RightBubble, contextTag, initialText, and language. It also sets default props for FooterInput, FooterProgress, FooterListener, LeftBubble, RightBubble, initialText, and language. 
  Within the component, there are state hooks for chatLog (which holds all the messages in the chat log), value (which is the input value), isRecording (which is a boolean that determines whether the component is currently recording), isEnded, isAnimating (which is a boolean that determines whether the progress animation is currently running), and idx (which keeps track of the message indices). 
  It also defines event handlers for handleDialogResponse, handleDialogRequest, handleDialogPartial, handleDialogRecordingDone and handleDialogEnded, which are used by the Nuance Mix Dialog API. The handleSubmitEditing function begins the conversation process and sets up the event listeners. The converse function is used to handle recording and Nuance Mix Dialog API functions. 
  Finally, the component returns a View which contains a FlatList of chat bubbles, a FooterInput, FooterListener and FooterProgress components, which are defined by their corresponding props (usually a microphone icon), that handle the recording and sending of messages.
*****/
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from "react";
import { TextInput, Text, View, StyleSheet, FlatList, NativeModules, NativeEventEmitter } from "react-native";
import PropTypes from "prop-types";
import Icon from "react-native-vector-icons/FontAwesome";


// This component provides a chat interface to the Nuance Mix Dialog API.
const NuanceMixChat = ({
  style,
  viewStyle,
  FooterInput,
  FooterListener,
  FooterProgress,
  LeftBubble,
  RightBubble,
  contextTag,
  language,
  ...rest
}) => {

  const [chatLog, onUpdateChatLog] = React.useState([]);
  const [value, onChangeText] = React.useState("");
  const [isRecording, setIsRecording] = React.useState(false);
  const [isEnded, setIsEnded] = React.useState(true);
  const [isAnimating, setIsAnimating] = React.useState(false);
  const [idx, incr] = React.useState(1);

  let scrollRef = React.useRef(null);

  const NuanceMix = NativeModules.NuanceMix;
  const myModuleEvt = new NativeEventEmitter(NativeModules.NuanceMix);
  NuanceMix.init("dlg");

  // Used by the FlatList to render the chat bubbles.
  const renderItem = ({item}) => {
    if (chatLog.length === 0) return(<View/>);
    if (item.sentMessage) {
      return (
          <RightBubble key={item.key} text={item.text} />
      );
  } else {
        return (
          <LeftBubble key={item.key} text={item.text} />
        );
    }
  };

  // Event handlers for the Nuance Mix Dialog API.
  function handleDialogResponse(result) {
    console.log("handleDialogResponse " + idx + " " + result);
    incr(idx => idx + 1);
    var elem = {id: 'resp'+idx, text: result, sentMessage: false};
    onUpdateChatLog(chatLog => [...chatLog, elem]);
    myModuleEvt.removeAllListeners('NuanceMixDialogResponse');
    myModuleEvt.removeAllListeners('NuanceMixDialogRequest');
    myModuleEvt.removeAllListeners('NuanceMixDialogPartial');
    myModuleEvt.removeAllListeners('NuanceMixDialogRecordingDone');
  };
  function handleDialogRequest(result) {
    console.log("handleDialogRequest " + idx + " " + result);
    incr(idx => idx + 1);
    var elem = {id: 'req'+idx, text: result, sentMessage: true};
    onUpdateChatLog(chatLog => [...chatLog, elem]);
    onChangeText("");
    if (FooterProgress) {
      setIsAnimating(false);
    }
    myModuleEvt.removeAllListeners('NuanceMixDialogRequest');
    myModuleEvt.removeAllListeners('NuanceMixDialogPartial');
  };
  function handleDialogPartial(partial) {
    console.log("handleDialogPartial " + partial);
    if (FooterInput) {
      onChangeText(partial);
    }
  };
  function handleDialogRecordingDone() {
    console.log("handleDialogRecordingDone " + isRecording);
    setIsRecording(false);
    setIsAnimating(false);
    myModuleEvt.removeAllListeners('NuanceMixDialogRecordingDone');
  };
  function handleDialogEnded() {
    console.log('handleDialogEnded ' + isEnded);
    setIsEnded(true);
  };
  function handleSubmitEditing() {
    myModuleEvt.addListener('NuanceMixDialogResponse', handleDialogResponse);
    myModuleEvt.addListener('NuanceMixDialogRequest', handleDialogRequest);
    myModuleEvt.addListener('NuanceMixDialogPartial', handleDialogPartial);
    myModuleEvt.addListener('NuanceMixDialogRecordingDone', handleDialogRecordingDone);  
    myModuleEvt.addListener('NuanceMixDialogEnded', handleDialogEnded);
    NuanceMix.converse(value, contextTag);
  }
  const converse = () => {
    if (idx!==1 && FooterProgress) {
      setIsAnimating(true);
    } 

    setIsRecording(true);
    setIsEnded(false);
    myModuleEvt.addListener('NuanceMixDialogResponse', handleDialogResponse);
    myModuleEvt.addListener('NuanceMixDialogRequest', handleDialogRequest);
    myModuleEvt.addListener('NuanceMixDialogPartial', handleDialogPartial);
    myModuleEvt.addListener('NuanceMixDialogRecordingDone', handleDialogRecordingDone);  
    myModuleEvt.addListener('NuanceMixDialogEnded', handleDialogEnded);
    NuanceMix.converse(null, contextTag);
  };

  // First time only - start the conversation.
  React.useEffect(() => {
    setIsRecording(true);
    setIsEnded(false);
    myModuleEvt.addListener('NuanceMixDialogResponse', handleDialogResponse);
    myModuleEvt.addListener('NuanceMixDialogRequest', handleDialogRequest);
    myModuleEvt.addListener('NuanceMixDialogPartial', handleDialogPartial);
    myModuleEvt.addListener('NuanceMixDialogRecordingDone', handleDialogRecordingDone);  
    myModuleEvt.addListener('NuanceMixDialogEnded', handleDialogEnded);

    NuanceMix.converse(null, contextTag);

    return () => {
      myModuleEvt.removeAllListeners('NuanceMixDialogResponse');
      myModuleEvt.removeAllListeners('NuanceMixDialogRequest');
      myModuleEvt.removeAllListeners('NuanceMixDialogPartial');
      myModuleEvt.removeAllListeners('NuanceMixDialogRecordingDone');
      myModuleEvt.removeAllListeners('NuanceMixDialogEnded');
    }
  }, []);

  // Returning a View which contains a FlatList of chat bubbles.
  return (
    <View style={viewStyle} {...rest}> 
      <View style={{backgroundColor: "black", height:1, width:"90%", alignSelf:"center"}} />
      <FlatList
        {...rest}
        contentContainerStyle={style}
        showsVerticalScrollIndicator={true}
        scrollEnabled={true}
        keyExtractor={item => item.id.toString()}
        data = {chatLog}
        renderItem ={renderItem}
        ref={(it) => (scrollRef.current = it)}
        onContentSizeChange={() => {
              if (chatLog.length > 0) 
               scrollRef.current?.scrollToEnd({animated: false})
        }}
        ListFooterComponentStyle={{flex:1, justifyContent: 'flex-end'}}
      />
      {FooterInput ? (<FooterInput
              value={value}
              onSubmitEditing={handleSubmitEditing}
              onChangeText={(text) => onChangeText(text)}
        />) : (<DefaultFooterInput
              value={value}
              onSubmitEditing={handleSubmitEditing}
              onChangeText={(text) => onChangeText(text)}
        />)}
      {FooterProgress && (<FooterProgress
              isAnimating={isAnimating}
        />)}
      {FooterListener ? (<FooterListener
              onPress={converse}
        />) : (<DefaultFooterListener onPress={converse}/>)}
    </View>
  );
};

// Default components for the chat bubbles, input, and listener.
function DefaultLeftBubble({ key, text }) {
  return (
    <View style={styles.chatLeft} key={key}>
        <Text style={{ fontSize: 16, color: "#000",justifyContent:"center" }} key={key}>{text}</Text>
        <View style={styles.leftArrow}></View>
        <View style={styles.leftArrowOverlap}></View>
    </View>
  );
}
function DefaultRightBubble({ key, text }) {
  return (
    <View style={styles.chatRight} key={key}>
        <Text style={{ fontSize: 16, color: "#fff",justifyContent:"center" }} key={key}>{text}</Text>
        <View style={styles.rightArrow}></View>
        <View style={styles.rightArrowOverlap}></View>
    </View>
  );
}
function DefaultFooterInput({ value, onSubmitEditing, onChangeText }) {
  return (
    <TextInput
      style={styles.chatInputStyle}
      value={value}
      onSubmitEditing={onSubmitEditing}
      onChangeText={(text) => onChangeText(text)}
    />
  )
}
function DefaultFooterListener({ onPress }) {
  return (
    <Icon
      style={styles.chatIcon}
      name="microphone"
      size={20}
      color="#000"
      onPress={onPress}
    />
  );
}

NuanceMixChat.defaultProps = {
  initialText: "",
  language: null,
  contextTag: null,
  FooterInput: DefaultFooterInput,
  FooterProgress: null,
  FooterListener: DefaultFooterListener,
  LeftBubble: DefaultLeftBubble,
  RightBubble: DefaultRightBubble,
}

NuanceMixChat.propTypes = {
  viewStyle: PropTypes.object,
  initialText: PropTypes.string,
  FooterInput: PropTypes.func,
  FooterProgress: PropTypes.func,
  FooterListener: PropTypes.func,
  LeftBubble: PropTypes.func,
  RightBubble: PropTypes.func,
  language: PropTypes.string,
  autoStart: PropTypes.bool,
  contextTag: PropTypes.string,
};

// Styling for the default components. Provide an iMessage-like appearance.
const styles = StyleSheet.create({
  chatIcon: {
    marginTop:2,
    marginBottom:2,
    marginLeft: "50%",
  },
  chatInputStyle: {
    marginTop: 4,
    marginBottom: 4,
    paddingHorizontal: 24,
    fontSize: 16,
    marginLeft: 5,
    marginRight: 5,
    borderWidth: 1,
    color:"black"
  },
  chatLeft: {
        backgroundColor: "#dedede",
        padding:10,
        borderRadius: 5,
        marginTop: 5,
        marginLeft: "5%",
        maxWidth: '70%',
        alignSelf: 'flex-start',
        borderRadius: 20,
    },
    chatRight: {
        backgroundColor: "#0078fe",
        padding:10,
        marginLeft: '45%',
        borderRadius: 5,
        marginTop: 5,
        marginRight: "5%",
        maxWidth: '50%',
        alignSelf: 'flex-end',
        borderRadius: 20,
    },
    /*Arrow head for sent messages*/
    rightArrow: {
      position: "absolute",
      backgroundColor: "#0078fe",
      width: 20,
      height: 25,
      bottom: 0,
      borderBottomLeftRadius: 25,
      right: -10
    },    
    rightArrowOverlap: {
      position: "absolute",
      backgroundColor:"white",
      width: 20,
      height: 35,
      bottom: -6,
      borderBottomLeftRadius: 18,
      right: -20
    
    },
    /*Arrow head for recevied messages*/
    leftArrow: {
        position: "absolute",
        backgroundColor: "#dedede",
        width: 20,
        height: 25,
        bottom: 0,
        borderBottomRightRadius: 25,
        left: -10
    },    
    leftArrowOverlap: {
        position: "absolute",
        backgroundColor:"white",
        width: 20,
        height: 35,
        bottom: -6,
        borderBottomRightRadius: 18,
        left: -20
    
    },});
  
export default NuanceMixChat;

