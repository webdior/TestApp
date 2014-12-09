package com {	
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import fl.transitions.Tween;
	import fl.transitions.easing.Regular;
	import fl.transitions.TweenEvent;
	import flash.net.URLLoader;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.Loader;
	
	public class Cole extends MovieClip {		
		private var startX:Number;
		private var startY:Number;
		private var capturedImage:Sprite;
		private var simplevid:SimpleVideo;
		private var destinations:Array;
		private var music:Sound;
		private var arrow:Arrow;
		
		private var dailyCounter:uint = 0;
		private var hourlyCounter:uint = 0;
		private var bonusNum:uint = 0;
		private var minutesSinceReset:uint = 1;
		private var hourlyMinutesSinceReset:uint = 1;
		
		public var piecesPerMinute:Number =  100;
		public var conveyorSpeed:Number =  108 / stage.frameRate;
		private var conveyorVertical:Boolean = true;
		private var aTweens:Array = new Array();
		public var filePath:String = "assets/";
		private var xml:XML;
		
		public function Cole() {
			if (root.loaderInfo.url.indexOf("file") == -1) {
				filePath = root.loaderInfo.url.substring(0, root.loaderInfo.url.lastIndexOf("/")+1);
			}
			trace("filePath:", filePath);
			var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, loadXML);
				loader.addEventListener(IOErrorEvent.IO_ERROR, loadXML);
				loader.load( new URLRequest( pathOf("Colebot.xml") ) );			
		}
		private function loadXML(e:Event):void {
			if (e.type == Event.COMPLETE) {
				xml = new XML(URLLoader(e.target).data);
				trace(xml);
				init();
			} else {
				trace("ERROR LOADING CONFIG XML\n" + IOErrorEvent(e).text);
			}
		}
		private function init():void {
			destinations = [waste, glass, food, plastic, aluminum, tin];
			for (var i:uint=0; i<destinations.length; i++) {
				destinations[i].mouseChildren=false;
				destinations[i].addEventListener(MouseEvent.CLICK, clickDestination);
				if (xml.box[i]) {
					trace("setting box", i, "to", xml.box[i].@name)
					destinations[i].title.text = xml.box[i].@name;
					loadImage(destinations[i], xml.box[i]);
				}
			}			
			
			btnFullScreen.addEventListener(MouseEvent.CLICK, toggleFullScreen);
			btnResetCounters.addEventListener(MouseEvent.CLICK, resetCounters);
			
			simplevid = new SimpleVideo( pathOf(xml.video) );
			simplevid.videoPlayerWidth = 800;
			simplevid.x = 200;
			simplevid.y = 200;
			simplevid.setVolume(0);
			simplevid.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);			
			simplevid.addEventListener("VideoComplete", handleVideoComplete);
			addChild(simplevid);			
			
			var minuteTimer:Timer = new Timer(60000, 0xFFFFFF);
				minuteTimer.addEventListener(TimerEvent.TIMER, minutely);
				minuteTimer.start();
			var hourTimer:Timer = new Timer(3600000, 0xFFFFFF);
				hourTimer.addEventListener(TimerEvent.TIMER, hourly);
				hourTimer.start();
			
			if (xml.music) {
				trace("Loading Music:", xml.music);
				music = new Sound( new URLRequest( pathOf(xml.music) ) );
				music.addEventListener(Event.COMPLETE, musicLoaded);
			}
			
			if (xml.conveyorSpeed) {
				conveyorSpeed =  xml.conveyorSpeed / stage.frameRate;
				trace("conveyorSpeed", xml.conveyorSpeed, "/", stage.frameRate, "=", conveyorSpeed);
			}
			if (xml.conveyorDirection) {
				switch (xml.conveyorDirection.toLowerCase()) {
					case "up":
						conveyorSpeed *= -1;
					case "down":
						conveyorVertical = true;
						break;
					case "left":
						conveyorSpeed *= -1;
					case "right":
						conveyorVertical = false;
						break;
					default:
						trace("ERROR—conveyorDirection not up down left or right:", xml.conveyorDirection);
				}
			}
			if (xml.piecesPerMinute) {
				piecesPerMinute =  xml.piecesPerMinute;
				trace("piecesPerMinute", piecesPerMinute);
			}
		}
		private function musicLoaded(e:Event):void {
			trace("musicLoaded", e.target)
			music.play(0, 0xFFFFFF);
		}
		private function handleVideoComplete(e:Event):void {
			trace("handleVideoComplete — Restarting");
			simplevid.replayVideo();
		}
		private function handleMouseDown(e:MouseEvent):void {
		//	trace("handleMouseDown", e.target, e.target.name);
		
			if (arrow) {
				capturedImage = null;
				removeChild(arrow);
				arrow = null;
			}
			
			arrow = new Arrow();
			arrow.x = startX = mouseX;
			arrow.y = startY = mouseY;
			addChild(arrow);
			stage.removeEventListener(Event.ENTER_FRAME, arrowFollowsConveyor);	
			
			stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
			stage.addEventListener(Event.ENTER_FRAME, handleMouseDrag);
			
			var whoosh:Whoosh = new Whoosh();
				whoosh.play();
		}
		private function clickDestination(e:MouseEvent):void {
			if (arrow) {
				trace("clickDestination", e.currentTarget.title.text);
				var coin:Coin = new Coin();
					coin.play();
				//removeChild(capturedImage);
				capturedImage = null;
				dailyCounter++
				hourlyCounter++
				e.currentTarget.tf.text = Number(e.currentTarget.tf.text) + 1;
				
				aTweens.push( new Tween(e.currentTarget.touch, "alpha", Regular.easeOut, e.currentTarget.touch.alpha, 1, 0.25, true) );
				aTweens[aTweens.length-1].addEventListener(TweenEvent.MOTION_FINISH, tweenOut);
				
				removeChild(arrow);
				arrow = null;
				stage.removeEventListener(Event.ENTER_FRAME, arrowFollowsConveyor);	
			}
		}
		private function tweenOut(e:TweenEvent):void {
			aTweens.push( new Tween(e.target.obj, "alpha", Regular.easeOut, 1, 0, 1.0, true) );
		}
		private function handleMouseUp(e:MouseEvent):void {
			try {
				stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
				stage.removeEventListener(Event.ENTER_FRAME, handleMouseDrag);
				stage.addEventListener(Event.ENTER_FRAME, arrowFollowsConveyor);				
				
				if (capturedImage) removeChild(capturedImage);
					capturedImage = drawRectangle();
				//addChild(capturedImage);
				if(capturedImage.width>2 && capturedImage.height > 2) {				
					var leftX:Number = Math.min(mouseX, startX);
					var rightX:Number = Math.max(mouseX, startX);
					var topY:Number = Math.min(mouseY, startY);
					var bottomY:Number = Math.max(mouseY, startY);
				//	trace(rightX-leftX, "x", bottomY-topY, "at", leftX-simplevid.x, "/", topY-simplevid.y);	
					var matrix:Matrix = new Matrix();
						matrix.translate(simplevid.x-leftX, simplevid.y-topY);
					var myBitmapData:BitmapData = new BitmapData(rightX-leftX, bottomY-topY);
						myBitmapData.draw(simplevid.video, matrix, null, null, new Rectangle(0, 0, rightX-leftX, bottomY-topY));
					var bitmap:Bitmap = new Bitmap(myBitmapData);
						bitmap.x = leftX - startX;
						bitmap.y = topY - startY;
					capturedImage.addChildAt(bitmap, 0);
				} else {
					//removeChild(capturedImage);
					capturedImage = null;
				}
			} catch (error:Error) {
				trace(e.currentTarget, e.currentTarget.name, error);
			}
		}
		private function handleMouseDrag(e:Event):void {
			//trace(mouseX, mouseY);
			if (arrow) {
				if (conveyorVertical) {
					arrow.y = startY += conveyorSpeed;
				} else {
					arrow.x = startX += conveyorSpeed;
				}
				var dX:Number = mouseX - startX;
				var dY:Number = mouseY - startY;
				arrow.arrowShape.width = Math.sqrt( dX*dX + dY*dY);
				//arrow.arrowShape.scaleY = arrow.arrowShape.scaleX;
				arrow.rotation = Math.atan2(dY, dX) * 180/Math.PI;
			}
		}
		private function arrowFollowsConveyor(e:Event):void {
			if (conveyorVertical) {
				arrow.y += conveyorSpeed;
			} else {
				arrow.x += conveyorSpeed;
			}
		}
		private function drawRectangle():Sprite {
			var rectangle:Shape = new Shape;
				rectangle.graphics.beginFill(0xFFFFFF, 0.2);
				rectangle.graphics.lineStyle(2, 0xFFFFFF, 1.0);
				rectangle.graphics.drawRect(0, 0, mouseX-startX, mouseY-startY);
				rectangle.graphics.endFill();
			var sprite:Sprite = new Sprite();
				sprite.x = startX;
				sprite.y = startY;
				sprite.addChild(rectangle);
			return sprite;
		}
		private function checkHit(e:Event=null):MovieClip {
			var hit:MovieClip;
			for (var i:uint=0; i<destinations.length; i++) {
				if (capturedImage.hitTestObject(destinations[i])) {
				//	trace(destinations[i].name);
					destinations[i].area.alpha = 1.0;
					hit = destinations[i];
				} else {
					destinations[i].area.alpha = 0.5;
				}
			}
			return hit;
		}
		private function toggleFullScreen (e:Event):void {
			trace("toggleFullScreen");
			if (stage.displayState == StageDisplayState.NORMAL) {
				try {
					stage.displayState = StageDisplayState.FULL_SCREEN; 
				} catch (e:Error) { trace(e) }
			} else if (stage.displayState == StageDisplayState.FULL_SCREEN) {
				stage.displayState = StageDisplayState.NORMAL;
			}
		}
		private function resetCounters(e:MouseEvent):void {
			for (var i:uint=0; i<destinations.length; i++) {
				destinations[i].tf.text = 0;
			}			
			tfToday.text = "0%";
			tfHour.text = "0%";
			tfBonus.text = "$0";
			dailyCounter = hourlyCounter = bonusNum = 0;
			minutesSinceReset = hourlyMinutesSinceReset = 1;
		}
		private function hourly(e:TimerEvent):void {
			trace("hourly");
			tfHour.text = "0%";
			hourlyCounter = 0;
			hourlyMinutesSinceReset = 1;
		}
		private function minutely(e:TimerEvent):void {
			trace("minutely");
			minutesSinceReset++
			hourlyMinutesSinceReset++
			bonusNum = Math.round( 100 * hourlyCounter / (piecesPerMinute * hourlyMinutesSinceReset) );
			tfToday.text = Math.round( 100 * dailyCounter / (piecesPerMinute * minutesSinceReset) ) + "%";
			tfHour.text = String( bonusNum ) + "%";
			tfBonus.text = "$" + ( bonusNum <= 15 ? 0 : bonusNum );
		}
		private function pathOf(file:String):String {
			if (file.indexOf("http") == 0) {
				return file;
			} else {
				return filePath + file;
			}
		}
		private function loadImage(target:MovieClip, file:String):void {
			trace("loadImage", file, "into", target.name);
			var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedImage);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadedImage);
				loader.load( new URLRequest( pathOf( file ) ) );
			target.removeChildAt(0);
			target.addChildAt(loader, 0);
		}
		private function loadedImage(e:Event):void {
			if (e.type == Event.COMPLETE) {
			//	trace("IMAGE LOADED", e.target.loader);
				e.target.loader.x -= e.target.loader.width/2;
				e.target.loader.y -= e.target.loader.height/2 - 16;
			} else {
				trace("ERROR LOADING IMAGE\n" + IOErrorEvent(e).text);
			}
		}
	}	
}