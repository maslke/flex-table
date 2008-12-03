package com.siloon.containers.table
{
	import com.siloon.containers.table.constant.CellConst;
	import com.siloon.containers.table.constant.CursorState;
	import com.siloon.containers.table.events.SelectCellEvent;
	import com.siloon.containers.table.events.SelectColumnEvent;
	import com.siloon.containers.table.events.SelectRowEvent;
	import com.siloon.containers.table.events.StartChangeCellWidthEvent;
	import com.siloon.containers.table.events.StartChangeRowHeightEvent;
	import com.siloon.containers.table.grid.GridItem;
	import com.siloon.plugin.rightClick.RightClickManager;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import mx.controls.TextArea;
	import mx.managers.IFocusManagerComponent;
	
	use namespace table_internal;
	
	/**
	* The value of the backgroundcolor when this cell is selected.
	*/
	[Style(name="selectedBackgroundColor",type="uint",format="Color",inherit="no")]
	
	public class Cell extends GridItem implements IFocusManagerComponent
	{
		public function Cell()
		{
			super();
		}
		
		private var _selected:Boolean = false;
		
		public function get selected():Boolean
		{
			return _selected;
		}
		
		table_internal function set selected(value:Boolean):void
		{
			if(value)
			{
				setStyle("backgroundColor",getStyle("selectedBackgroundColor"));
				_selected = true;
			}
			else
			{
				setStyle("backgroundColor",null);
				_selected = false;
			}
		}
		
		public function get previous():Cell
		{
			var _previous:Cell;
			var row:Row = Row(parent);
			var position:int = row.getChildIndex(this);
			var count:int = row.getChildren().length;
			
			if(position == 0)
			{
				_previous = null;
			}
			else
			{
				_previous = Cell(row.getChildAt(position - 1));
			}
			
			return _previous;
		}
		
		public function get next():Cell
		{
			var _next:Cell;
			
			var row:Row = Row(parent);
			var position:int = row.getChildIndex(this);
			var count:int = row.getChildren().length;
			if(position == count-1)
			{
				_next = null;
			}
			else
			{
				_next = Cell(row.getChildAt(position + 1));
			}
			
			return _next;
		}
		
		/**
		 * 
		 * @return get the index of this cell among the cells 
		 * contained in the parent row. 
		 * 
		 */
		public function get position():int
		{
			return Row(parent).getChildIndex(this);
		}
		
		table_internal function get topLeftX():Number
		{
			return parent.parent.globalToLocal(parent.localToGlobal(new Point(x,y))).x;
		}

		table_internal function get topRightX():Number
		{
			return parent.parent.globalToLocal(parent.localToGlobal(new Point(x,y))).x + width;
		}
		
		table_internal function get gridRowIndex():int
		{
			return Row(parent).gridRowIndex;
		}
		
		/**
		 * 
		 * @return get the rows which contains or are spanned 
		 * by this cell.
		 * 
		 */
		table_internal function get rows():Array
		{
			var spannedRows:Array = new Array();
			
			var i:int;
			var row:Row;
			var rows:Array = Table(parent.parent).rows;
			
			for( i = 0 ;i < rows.length ;i++)
			{
				row = Row(rows[i]);
				if(!(row.gridRowIndex < gridRowIndex || row.gridRowIndex > gridRowIndex + gridRowSpan - 1))
				{
					spannedRows.push(row);
				}
			}
			
			return spannedRows;
		}		
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
			addEventListener(MouseEvent.DOUBLE_CLICK,doubleClickHandler);
			addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			addEventListener(RightClickManager.RIGHT_CLICK,rightClickHandler);								
		}
		
		override protected function commitProperties():void
		{			
			setStyle("selectedBackgroundColor",0xcccccc);
			setStyle("borderStyle","solid");
			setStyle("borderColor",0x000000);
			
			horizontalScrollPolicy = "off";
			verticalScrollPolicy = "off";
			
			// when mouse moves into this area, if the cell
			// is contained in the first row, the cursorState
			// will be SELECT_COLUMN, else it will be 
			// CHANGE_ROW_HEIGHT.
			setStyle("paddingTop",CellConst.PADDING_TOP);			
			// when mouse moves into this area, if the cell
			// is contained in the last row, the cursorState
			// will be CHANGE_ROW_HEIGHT.
			setStyle("paddingBottom",CellConst.PADDING_BOTTOM);
			// when mouse moves into this area, the cursorState
			// will be SELECT_CELL.
			setStyle("paddingLeft",CellConst.PADDING_LEFT);
			// when mouse moves into this area, if the cell
			// is not contained in the last column, the 
			// cursorState will be CHANGE_COLUMN_WIDTH.
			setStyle("paddingRight",CellConst.PADDING_RIGHT);
			
			// this makes the height of the cell increasing 
			// automatically when its parent row's height is 
			// changed.
						
			super.commitProperties();
		}
		
		override public function setFocus():void
		{
			super.setFocus();
		}
		
		/***************************************************************
		 * MOUSE HANDLERS
		 * *************************************************************
		 */		
		
		private function rightClickHandler(event:MouseEvent):void
		{
			var table:Table = Table(parent.parent);
			if(!table.selectedCells.contains(this))
			{
				table.dispatchEvent(new SelectCellEvent(this,event.ctrlKey,event.shiftKey));
			}
		}
		
		private function mouseDownHandler(event:MouseEvent):void
		{
			var evt:MouseEvent;
			
			if(isDoubleClick())
			{
				evt = new MouseEvent(MouseEvent.DOUBLE_CLICK);
				evt.ctrlKey = event.altKey;
				evt.buttonDown = event.buttonDown;
				evt.ctrlKey = event.ctrlKey;
				evt.delta = event.delta;
				evt.localX = event.localX;
				evt.localY = event.localY;
				evt.shiftKey = event.shiftKey;							
				dispatchEvent(evt);
			}
			else
			{
				var table:Table = Table(parent.parent);
			 	var targetCell:Cell;
			 	var cell:Cell;
			 	var row:Row;
			 	var i:int;
			 	var children:Array;
			 	
			 	var previousRowPosition:int;
				var previousRow:Row ;
			 	
				switch(Table.cursorState)
				{
					case CursorState.NORMAL:				
						break;
					case CursorState.CHANGE_COLUMN_WIDTH:	
						var leftCell:Cell;
						var rightCell:Cell;
						var rightCellColIndex:int;
						var targetRow:Row;
						
						leftCell = this;
						rightCellColIndex = leftCell.gridColIndex + leftCell.gridColSpan;

						var point:Point = new Point(0,mouseY);
						point = localToGlobal(point);
						point = table.globalToLocal(point);												
						
						children = table.getChildren();
						
						for( i = 0 ;i < children.length ; i++)
						{
							row = Row(children[i]);
							if(row.gridRowIndex >= leftCell.gridRowIndex &&
								row.gridRowIndex < leftCell.gridRowIndex + leftCell.gridRowSpan )
							{
								if(point.y >= row.y && point.y <= row.y + row.height)
								{
									targetRow = row;
									break;
								}
							}
						}
						
						previousRowPosition = table.getChildIndex(targetRow) + 1;
						
						while(rightCell == null)
						{
							previousRowPosition --;
							previousRow = Row(table.getChildAt(previousRowPosition)); 
							children = previousRow.getChildren();	
							
							for( i = 0 ;i < children.length ; i++)
							{
								cell = Cell(children[i]);
								if(cell.gridColIndex == leftCell.gridColIndex + leftCell.gridColSpan)
								{
									rightCell = cell;
									break;
								}
							}												
						}
																																
						table.dispatchEvent(new StartChangeCellWidthEvent(leftCell,rightCell,targetRow));			
						break;
					case CursorState.CHANGE_ROW_HEIGHT:																							
						previousRowPosition = parent.parent.getChildIndex(parent);
						
						while(targetCell == null)
						{
							previousRowPosition--;
							if(previousRowPosition == -1)
							{
								previousRowPosition = 0;
							}
							previousRow = Row(parent.parent.getChildAt(previousRowPosition));
							
							children = previousRow.getChildren();
							
							for( i = 0 ;i < children.length ; i++)
							{
								cell = Cell(children[i]);
								
								if(cell.gridColIndex + cell.gridColSpan <= gridColIndex)
								{
									continue;
								}
								
								if(cell.gridColIndex >= gridColIndex + gridColSpan)
								{
									continue;
								}
								
								targetCell = cell;
								break;
							}
						}
						
						if( gridRowIndex + gridRowSpan - 1 == Row(parent).gridRowHeights.length - 1)
						{
							if(mouseY >= height - CellConst.PADDING_BOTTOM)
							{
								targetCell = this;
							}
						}
						
						table.dispatchEvent(new StartChangeRowHeightEvent(targetCell));
						break;
					case CursorState.SELECT_CELL:
						table.dispatchEvent(new SelectCellEvent(this,event.ctrlKey,event.shiftKey));
						break;
					case CursorState.SELECT_COLUMN:
						table.dispatchEvent(new SelectColumnEvent(gridColIndex,event.ctrlKey,event.shiftKey));
						break;
				}
			}
		}
		
		private function mouseMoveHandler(event:MouseEvent):void
		{
			if(isSelectColumn())
			{
				Table.cursorState = CursorState.SELECT_COLUMN;
			}
			else if(isSelectCell())
			{
				Table.cursorState = CursorState.SELECT_CELL;
			}
			else if(isChangeRowHeight())
			{
				Table.cursorState = CursorState.CHANGE_ROW_HEIGHT;
			}
			else if(isChangeColumnWidth())
			{
				Table.cursorState = CursorState.CHANGE_COLUMN_WIDTH;
			}
			else
			{
				Table.cursorState = CursorState.NORMAL;
			}
			
			Table(parent.parent).updateCursor();
		}
		
		private function isSelectColumn():Boolean
		{
			if(gridRowIndex == 0)
			{
				if(mouseY <= CellConst.PADDING_TOP)
				{
					return true;
				} 
			}
			return false;
		}
		
		private function isSelectCell():Boolean
		{
			if(mouseX < CellConst.PADDING_LEFT)
			{
				return true;
			}
			
			if(mouseY > CellConst.PADDING_TOP 
			   && mouseY < height - CellConst.PADDING_BOTTOM
			   && mouseX < width - CellConst.PADDING_RIGHT
			   && numChildren == 0)
			{
			   	return true;
			}
			return false;
		}
		
		private function isChangeRowHeight():Boolean
		{
			if(gridRowIndex != 0)
			{
				if(mouseY <= CellConst.PADDING_TOP)
				{
					return true;
				}
			}
			
			if( gridRowIndex + gridRowSpan - 1 == Row(parent).gridRowHeights.length - 1)
			{
				if(mouseY >= height - CellConst.PADDING_BOTTOM)
				{
					return true;
				}
			}
			return false;
		}		
		
		private function isChangeColumnWidth():Boolean
		{
			if(gridColIndex + gridColSpan - 1 != Row(parent).gridColumnWidths.length - 1)
			{
				if(mouseX >= width - CellConst.PADDING_RIGHT)
				{
					return true;
				}
			}
			return false;
		}
		
		private function doubleClickHandler(event:MouseEvent):void
		{
			if(Table.cursorState == CursorState.SELECT_CELL)
			{
				Table(parent.parent).dispatchEvent(new SelectRowEvent(Row(parent),event.ctrlKey,event.shiftKey));
			}
		}
		
		// these codes is used to detect if the mouse is double clicked.
		private var a:Number = 0;
		private var b:Number = 0 ;
		private var c:Number = 0;
		
		private function isDoubleClick():Boolean
		{
			b = a;
			a = getTimer();
			c = a-b;
			if(c<300&&c>0)
			{
				return true;
			}		
			else
			{
				return false;
			}
			a = 0;
			b = 0;
			c = 0;
		}
	}
}