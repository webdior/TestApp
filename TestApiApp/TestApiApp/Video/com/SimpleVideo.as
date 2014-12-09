//http://www.codingcolor.com/as3/as-3-simple-video-player/
package com {
	import flash.display.*;
	import flash.net.NetConnection;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.events.NetStatusEvent;
	import flash.media.SoundTransform;
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	public class SimpleVideo extends Sprite {
		public var video:Video;
		private var nc:NetConnection;
		private var ns:NetStream;
		private var newSizesByWidth:Object;
		private var isAutoPlay:Boolean;
		private var videoUrl:String;
		private var videoDuration:int;
		private var parentClip:MovieClip;
		private var volumeTransform:SoundTransform;
		private var duration:int;
		private var netStatusCache:String;
		private var addToParentClip:Boolean = false;
		private var isVideoReady:Boolean = false;
		private var videoWidth:int = 350;
		public function SimpleVideo(videoPath:String, isAuto:Boolean=true, inParentClip:MovieClip=null):void {
			videoUrl = videoPath;
			isAutoPlay = isAuto;
			parentClip = inParentClip;
			if (parentClip != null) {
				addToParentClip = true;
			}
			volumeTransform = new SoundTransform();
			nc = new NetConnection();
			nc.connect(null);
			ns = new NetStream(nc);
			ns.checkPolicyFile = true;	//JAY Added so we can capture bitmaps
			ns.client = {onMetaData:ns_onMetaData};
			ns.bufferTime = 5;
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusEvent);
			//video.attachNetStream(ns);
			if (isAutoPlay) {
				//ns.play(videoUrl+"?cacheKiller="+(new Date()).getTime());
				ns.play(videoUrl);
			}
		}
		public function set videoPlayerWidth(inNumber:int):void {
			videoWidth = inNumber;
		}
		public function stopVideo():void {
			ns.seek(0);
			ns.pause();
		}
		public function replayVideo():void {
			ns.seek(0);
		}
		public function pauseVideo():void {
			toggleVideo();
		}
		public function playVideo():void {
			toggleVideo();
		}
		public function setVolume(newVolume:Number):void {
			//The volume, from 0 (silent) to 1 (full volume).
			volumeTransform.volume = newVolume;
			ns.soundTransform = volumeTransform;
		}
		private function toggleVideo():void {
			if (! isVideoReady) {
				//ns.play(videoUrl+"?cacheKiller="+(new Date()).getTime());
				ns.play(videoUrl);
			}
			if (isVideoReady) {
				ns.togglePause();
			}
		}
		private function ns_onMetaData(_data:Object):void {
			duration = _data.duration;
			if (! isVideoReady) {
				isVideoReady = true;
			}
			newSizesByWidth = constrainSizeToWidth(_data.width,_data.height,videoWidth);
			trace("native:", _data.width+"x"+_data.height, "specified width:", videoWidth, "proportional height:", newSizesByWidth.height)
			video = new Video(newSizesByWidth.width, newSizesByWidth.height);
			video.smoothing = true;
			video.attachNetStream(ns);
			if (addToParentClip) {
				parentClip.addChild(video);
			} else {
				addChild(video);
			}
		}
		private function netStatusEvent(event:NetStatusEvent):void {
			if (netStatusCache != event.info.code) {
				switch (event.info.code) {
					case "NetStream.Play.Start" :
						break;
					case "NetStream.Buffer.Empty" :
						break;
					case "NetStream.Buffer.Full" :
						break;
					case "NetStream.Buffer.Flush" :
						break;
					case "NetStream.Seek.Notify" :
						break;
					case "NetStream.Seek.InvalidTime" :
						break;
					case "NetStream.Play.Stop" :
						dispatchEvent(new Event("VideoComplete"));
						break;
				}
				netStatusCache = event.info.code;
			}
		}
		private function constrainSizeToWidth(oldW:Number,oldH:Number,newW:Number):Object {
			return {width:newW,height:newW / oldW * oldH};
		}
		private function constrainSizeToHeight(oldW:Number, oldH:Number, newH:Number):Object {
			return {width:newH / oldH * oldW,height:newH};
		}
	}
}