package com.siloon.containers.table.events
{
	import com.siloon.containers.table.Cell;
	
	import flash.events.Event;
	
	public class SelectCellEvent extends Event
	{
		public static const SELECT_CELL:String = "selectCell";
		
		private var _targetCell:Cell;
		
		public function get targetCell():Cell
		{
			return _targetCell;
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
		
		public function SelectCellEvent(targetCell:Cell,ctrlKey:Boolean,shiftKey:Boolean)
		{
			super(SELECT_CELL);
			_targetCell = targetCell;
			_ctrlKey = ctrlKey;
			_shiftKey = shiftKey;
		}

	}
}