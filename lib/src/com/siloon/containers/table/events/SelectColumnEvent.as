package com.siloon.containers.table.events
{
	import com.siloon.containers.table.Cell;
	
	import flash.events.Event;
	
	public class SelectColumnEvent extends Event
	{
		public static const SELECT_COLUMN:String = "selectColumn";
		
		private var _targetColumnIndex:int;
		
		public function get targetColumnIndex():int
		{
			return _targetColumnIndex;
		}
		
		private var _ctrlKey:Boolean;
		
		public function get ctrlKey():Boolean
		{
			return _ctrlKey;
		}
		
		private var _shiftKey:Boolean;
		
		public function get shiftKey():Boolean
		{
			return _shiftKey;
		}
		
		public function SelectColumnEvent(targetColumnIndex:int,ctrlKey:Boolean,shiftKey:Boolean)
		{
			super(SELECT_COLUMN);
			_targetColumnIndex = targetColumnIndex;
			_ctrlKey = ctrlKey;
			_shiftKey = shiftKey;
		}

	}
}