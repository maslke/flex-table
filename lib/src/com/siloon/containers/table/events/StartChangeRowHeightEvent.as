package com.siloon.containers.table.events
{
	import com.siloon.containers.table.Cell;
	
	import flash.events.Event;
	
	public class StartChangeRowHeightEvent extends Event
	{
		public static const START_CHANGE_ROW_HEIGHT:String = "startChangeRowHeight";
		
		private var _targetCell:Cell;
		
		public function get targetCell():Cell
		{
			return _targetCell;
		}
		
		public function StartChangeRowHeightEvent(targetCell:Cell)
		{
			super(START_CHANGE_ROW_HEIGHT);
			_targetCell = targetCell;			
		}

	}
}