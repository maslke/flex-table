package com.siloon.containers.table.events
{
	import com.siloon.containers.table.Cell;
	import com.siloon.containers.table.Row;
	
	import flash.events.Event;
	
	public class StartChangeCellWidthEvent extends Event
	{
		public static const START_CHANGE_CELL_WIDTH:String = "startChangeCellWidth";
		
		private var _leftCell:Cell;
		
		public function get leftCell():Cell
		{
			return _leftCell;
		}
		
		private var _rightCell:Cell;
		
		public function get rightCell():Cell
		{
			return _rightCell;
		}
		
		private var _targetRow:Row;
		
		public function get targetRow():Row
		
		{
			return _targetRow;
		}
		
		public function StartChangeCellWidthEvent(leftCell:Cell,rightCell:Cell,targetRow:Row)
		{
			super(START_CHANGE_CELL_WIDTH);
			_leftCell = leftCell;
			_rightCell = rightCell;
			_targetRow = targetRow;
		}
	}
}