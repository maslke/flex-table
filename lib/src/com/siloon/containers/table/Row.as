package com.siloon.containers.table
{	
	import com.siloon.containers.table.grid.GridRow;
	
	use namespace table_internal;
	
	public class Row extends GridRow
	{
		public function Row()
		{
			super();
		}
		
		public function get previous():Row
		{
			var rowPostion:int = parent.getChildIndex(this);
			rowPostion --;
			if(rowPostion!=-1)
			{
				return Row(parent.getChildAt(rowPostion));
			}
			return null;
		}
		
		public function get next():Row
		{
			var rowPostion:int = parent.getChildIndex(this);
			rowPostion ++;
			if(rowPostion != parent.numChildren)
			{
				return Row(parent.getChildAt(rowPostion));
			}
			return null;
		}
		
		/**
		 * 
		 * @return get the cells which is contained in or span over this row.
		 * 
		 */
		public function get cells():Array
		{
			var i:int;
			var cell:Cell;
			
			var cellsSpanThisRow:Array = new Array();
			var cells:Array = Table(parent).cells;
			
			for(i = 0;i < cells.length;i++)
			{
				cell = Cell(cells[i]);
				if(cell.gridRowIndex <= gridRowIndex && cell.gridRowIndex + cell.gridRowSpan >= gridRowIndex + gridRowSpan)
				{
					cellsSpanThisRow.push(cell);
				}
			}
			return cellsSpanThisRow;
		}
		
		/**
		 * 
		 * @return get the index of this row among the rows contained in
		 * the parent table.
		 * 
		 */
		public function get position():int
		{
			return Table(parent).getChildIndex(this);
		}
		
		/**
		 * 
		 * @return get the minimum value of the property <code>gridRowSpan</code>
		 * of each cell contained in this row.
		 * 
		 * @see com.siloon.containers.table.cell#gridRowSpan
		 * 
		 */
		table_internal function get gridRowSpan():int
		{
			var i:int;
			var cell:Cell;
			
			var minRowSpan:int = int.MAX_VALUE;
			
			var children:Array = getChildren();
			
			for( i = 0 ;i < children.length;i++)
			{
				cell = Cell(children[i]);
				minRowSpan = Math.min(minRowSpan,cell.gridRowSpan);
			}
			return minRowSpan;
		}		
		
		override protected function measure():void
		{
			super.measure();
		}				
	}
}