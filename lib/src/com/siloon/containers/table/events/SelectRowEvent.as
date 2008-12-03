package com.siloon.containers.table.events
{
	import com.siloon.containers.table.Row;
	
	import flash.events.Event;
	
	public class SelectRowEvent extends Event
	{
		public static const SELECT_ROW:String = "selectRow";
		 
		private var _targetRow:Row;
		
		public function get targetRow():Row
		{
			return _targetRow;
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
		
		public function SelectRowEvent(targetRow:Row,ctrlKey:Boolean,shiftKey:Boolean)
		{
			super(SELECT_ROW);
			_targetRow = targetRow;
			_ctrlKey = ctrlKey;
			_shiftKey = shiftKey;
		}

	}
}