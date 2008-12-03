package com.siloon.containers.table.events
{
	import flash.events.Event;
	
	public class EndChangeRowHeightEvent extends Event 
	{
		public static const END_CHANGE_ROW_HEIGHT:String = "endChangeRowHeight";
		public function EndChangeRowHeightEvent()
		{
			super(END_CHANGE_ROW_HEIGHT);
		}

	}
}