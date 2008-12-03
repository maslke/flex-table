package com.siloon.containers.table.events
{
	import flash.events.Event;
	
	public class EndChangeColumnWidthEvent extends Event
	{
		public static const END_CHANGE_COLUMN_WIDTH:String = "endChangeColumnWidth";
		public function EndChangeColumnWidthEvent()
		{
			super(END_CHANGE_COLUMN_WIDTH);
		}

	}
}