package com.siloon.containers.table.events
{
	import flash.events.Event;
	
	public class EndChangeCellWidthEvent extends Event
	{
		public static const END_CHANGE_CELL_WIDTH:String = "endChangeCellWidth";
		
		public function EndChangeCellWidthEvent()
		{
			super(END_CHANGE_CELL_WIDTH);
		}

	}
}