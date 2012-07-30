/**
 * BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
 *
 * Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
 *
 * This program is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation; either version 2.1 of the License, or (at your option) any later
 * version.
 *
 * BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
 * 
 * Author: Ajay Gopinath <ajgopi124(at)gmail(dot)com>
 */
package org.bigbluebutton.modules.whiteboard.business.shapes
{
	import com.asfusion.mate.core.GlobalDispatcher;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import flashx.textLayout.edit.SelectionManager;
	
	import flexlib.scheduling.scheduleClasses.utils.Selection;
	
	import mx.controls.Text;
	
	import org.bigbluebutton.common.LogUtil;
	import org.bigbluebutton.modules.whiteboard.WhiteboardCanvasModel;

	public class TextObject extends TextField implements GraphicObject {
		public static const TYPE_NOT_EDITABLE:String = "dynamic";
		public static const TYPE_EDITABLE:String = "editable";
		
		public static const TEXT_CREATED:String = "textCreated";
		public static const TEXT_UPDATED:String = "textEdited";
		public static const TEXT_PUBLISHED:String = "textPublished";
		
		public static const TEXT_TOOL:String = "textTool";
		
		/**
		 * Status = [CREATED, UPDATED, PUBLISHED]
		 */
		public var status:String = TEXT_CREATED;

		private var _editable:Boolean;
		
		/**
		 * ID we can use to match the shape in the client's view
		 * so we can use modify it; a unique identifier of each GraphicObject
		 */
		private var ID:String = WhiteboardConstants.ID_UNASSIGNED;
		public var textSize:Number;
		
        private var origX:Number;
        private var origY:Number;
        private var _origParentWidth:Number = 0;
        private var _origParentHeight:Number = 0;
        public var fontStyle:String = "arial";
        
		public function TextObject(text:String, textColor:uint, bgColor:uint, bgColorVisible:Boolean, x:Number, y:Number, textSize:Number) {
			this.text = text;
			this.textColor = textColor;
			this.backgroundColor = bgColor;
			this.background = bgColorVisible;
            origX = x;
            origY = y;
            this.x = x;
            this.y = y;
			this.textSize = textSize;
		}	
		
        public function getOrigX():Number {
            return origX;
        }
        
        public function getOrigY():Number {
            return origY;
        }
        
		public function getGraphicType():String {
			return WhiteboardConstants.TYPE_TEXT;
		}
		
		public function getGraphicID():String {
			return ID;
		}
		
		public function setGraphicID(id:String):void {
			this.ID = id;
		}
		
		public function denormalize(val:Number, side:Number):Number {
			return (val*side)/100.0;
		}
		
		public function normalize(val:Number, side:Number):Number {
			return (val*100.0)/side;
		}
		
		private function applyTextFormat(size:Number):void {
//            LogUtil.debug(" *** Font text size [" + textSize + "," + size + "]");
			var tf:TextFormat = new TextFormat();
			tf.size = size;
			tf.font = "arial";
			this.defaultTextFormat = tf;
			this.setTextFormat(tf);
		}
		
		public function makeGraphic(parentWidth:Number, parentHeight:Number):void {
            this.x = denormalize(origX, parentWidth);
            this.y = denormalize(origY, parentHeight);
            
            var newFontSize:Number = textSize;
            
            if (_origParentHeight == 0 && _origParentWidth == 0) {
//                LogUtil.debug("Old parent dim [" + _origParentWidth + "," + _origParentHeight + "]");
                newFontSize = textSize;
                _origParentHeight = parentHeight;
                _origParentWidth = parentWidth;               
            } else {
                newFontSize = (parentHeight/_origParentHeight) * textSize;
//                LogUtil.debug("2 Old parent dim [" + _origParentWidth + "," + _origParentHeight + "] newFontSize=" + newFontSize);
            }            
			this.antiAliasType = AntiAliasType.ADVANCED;
            applyTextFormat(newFontSize);
//            setTextFormat(new TextFormat(fontStyle, newFontSize, textColor));
            
			// ensure typing doesn't go off of whiteboard
//			this.width = 250;
		}	

        public function get oldParentWidth():Number {
            return _origParentWidth;
        }
        
        public function get oldParentHeight():Number {
            return _origParentHeight;
        }
        
        public function redrawText(origParentWidth:Number, origParentHeight:Number, parentWidth:Number, parentHeight:Number):void {
            this.x = denormalize(origX, parentWidth);
            this.y = denormalize(origY, parentHeight);
            
            var newFontSize:Number = textSize;
            newFontSize = (parentHeight/origParentHeight) * textSize;
			
			/** Pass around the original parent width and height when this text was drawn. 
			 * We need this to redraw the the text to the proper size properly.
			 * **/
            _origParentHeight = origParentHeight;
            _origParentWidth = origParentWidth;               
                
//            LogUtil.debug("Redraw 2 Old parent dim [" + origParentWidth + "," + origParentHeight + "] newFontSize=" + newFontSize);
     
            this.antiAliasType = AntiAliasType.ADVANCED;
            applyTextFormat(newFontSize);
            //            setTextFormat(new TextFormat(fontStyle, newFontSize, textColor));
            
            // ensure typing doesn't go off of whiteboard
//            this.width = 250;
        }
        
		public function getProperties():Array {
			var props:Array = new Array();
			props.push(this.text);
			props.push(this.textColor);
			props.push(this.backgroundColor);
			props.push(this.background);
			props.push(this.x);
			props.push(this.y);
			return props;
		}
		
		public function makeEditable(editable:Boolean):void {
			if(editable) {
				this.type = TextFieldType.INPUT;
			} else {
				this.type = TextFieldType.DYNAMIC;
			}
			this._editable = editable;
		}
		
		public function registerListeners(textObjGainedFocus:Function, textObjLostFocus:Function, textObjTextListener:Function, textObjDeleteListener:Function):void {											  
			this.addEventListener(FocusEvent.FOCUS_IN, textObjGainedFocus);
			this.addEventListener(FocusEvent.FOCUS_OUT, textObjLostFocus);
			this.addEventListener(TextEvent.TEXT_INPUT, textObjTextListener);
			this.addEventListener(KeyboardEvent.KEY_DOWN, textObjDeleteListener);
		}		
		
		public function deregisterListeners(textObjGainedFocus:Function, textObjLostFocus:Function, textObjTextListener:Function, textObjDeleteListener:Function):void {			
			this.removeEventListener(FocusEvent.FOCUS_IN, textObjGainedFocus);
			this.removeEventListener(FocusEvent.FOCUS_OUT, textObjLostFocus);
			this.removeEventListener(TextEvent.TEXT_INPUT, textObjTextListener);
			this.removeEventListener(KeyboardEvent.KEY_DOWN, textObjDeleteListener);
		}
	}
}