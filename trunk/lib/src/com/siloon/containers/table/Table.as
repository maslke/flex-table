package com.siloon.containers.table
{
	import com.siloon.containers.table.constant.CellConst;
	import com.siloon.containers.table.constant.Cursor;
	import com.siloon.containers.table.constant.CursorState;
	import com.siloon.containers.table.constant.MenuConst;
	import com.siloon.containers.table.events.EndChangeCellWidthEvent;
	import com.siloon.containers.table.events.EndChangeColumnWidthEvent;
	import com.siloon.containers.table.events.EndChangeRowHeightEvent;
	import com.siloon.containers.table.events.SelectCellEvent;
	import com.siloon.containers.table.events.SelectColumnEvent;
	import com.siloon.containers.table.events.SelectRowEvent;
	import com.siloon.containers.table.events.StartChangeCellWidthEvent;
	import com.siloon.containers.table.events.StartChangeRowHeightEvent;
	import com.siloon.containers.table.grid.Grid;
	import com.siloon.containers.table.utils.SplitCellDialog;
	import com.siloon.plugin.rightClick.RightClickManager;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Menu;
	import mx.controls.TextArea;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.MenuEvent;
	
	use namespace table_internal;
	
	public class Table extends Grid
	{
		public function Table()
		{
			super();
			_selectedCells = new ArrayCollection();
			selectedColumns = new Array;
		}
		
		private static var menus:Array;
		
		public static function createTable(width:int,numRows:int,numColumns:int):Table
		{
			if(numRows < 1 )
			{
				numRows = 1;
			}
			
			if(numColumns < 1)
			{
				numColumns = 1;
			}
			
			if(width < CellConst.MIN_WIDTH*numColumns )
			{
				width = CellConst.MIN_WIDTH*numColumns;
			}
			
			var height:int = CellConst.MIN_HEIGHT * numRows;
			
			var table:Table = new Table();	
			table.originWidth = width;
			
			// the actual width of table is smaller than or equal to the specified one "width:int".
			var gridColumnNum:int = Math.floor(width / CellConst.BASIC_WIDTH);
			
			// the actual height of table is smaller than or equal to the specified one "var height:int".
			var gridRowNum:int = Math.floor(height / CellConst.BASIC_HEIGHT);
			
			var rowCount:int = gridRowNum % numRows;
						
			for(var i:int = 0;i < numRows;i++)
			{
				var row:Row = new Row();
				table.addChild(row);	
				
				row.height = CellConst.MIN_HEIGHT;	
				
				var rowSpan:int = Math.floor(gridRowNum / numRows);
				
				if(rowCount!=0)
				{
					rowSpan++;
					rowCount--;
				}
				
				var cellCount:int = gridColumnNum % numColumns;
				
				for(var j:int = 0;j < numColumns;j++)
				{
					var cell:Cell = new Cell();
					row.addChild(cell);	
																
					cell.gridRowSpan = rowSpan;				
					
					var colSpan:int = Math.floor(gridColumnNum / numColumns);
					
					if(cellCount!=0)
					{
						colSpan++;
						cellCount--;
					}
					
					cell.width = CellConst.BASIC_WIDTH * colSpan;
					cell.gridColSpan = colSpan;
				}												
			}
			
			return table;
		}
				
		table_internal static var cursorState:int;		
		
		private var _selectedCells:ArrayCollection;
		
		public function get selectedCells():ArrayCollection
		{
			return _selectedCells;
		}
		
		private var _originWidth:Number = 0;
		
		table_internal function get originWidth():Number
		{
			return _originWidth;
		}
		
		table_internal function set originWidth(value:Number):void
		{
			_originWidth = value;
			width = _originWidth;
		}
				
		private var draggingSource:*;
		private var dragging:Boolean = false;
		private var draggingDropPosition:Number = -1;
		
		private var lastSelectedCellBeforePressShiftKey:Cell;
		
		private var selectedColumns:Array;
		private var lastSelectedColumnIndexBeforePresShiftKey:int = -1;
		
		public function get rows():Array
	    {
	    	return getChildren();
	    }
	    
		public function get cells():Array
		{
			var i:int;
			var j:int;
			var row:Row;
			var cell:Cell;
			
			var cells:Array = new Array();
			var children:Array = getChildren();
			var rowChildren:Array;
			
			for( i = 0; i < children.length ; i++)
			{
				row = Row(children[i]);
				rowChildren = row.getChildren();
				
				for( j = 0; j < rowChildren.length ; j++)
				{
					cell = Cell(rowChildren[j]);
					cells.push(cell);
				}
			}
			return cells;
		}
		
		private function get allowMerge():Boolean
		{
			if(selectedCells.length <2)
			{
				return false;
			}

			var minColIndex:int = int.MAX_VALUE;
			var maxColIndex:int = -1;
			var minRowIndex:int = int.MAX_VALUE;
			var maxRowIndex:int = -1;
			var cell:Cell;
			var i:int;
			var j:int;
			
			for each(cell in selectedCells)
			{
				minColIndex = Math.min(minColIndex,cell.gridColIndex);
				maxColIndex = Math.max(maxColIndex,cell.gridColIndex + cell.gridColSpan - 1);
				
				minRowIndex = Math.min(minRowIndex,cell.gridRowIndex);
				maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex + cell.gridRowSpan - 1);
			}
			
			var rowArray:Array = new Array();
			
			for(i = minRowIndex ; i <= maxRowIndex ;i++)
			{
				var colArray:Array = new Array();
				
				for(j = minColIndex ; j <= maxColIndex ;j++)
				{
					colArray.push(0);
				}
				
				rowArray.push(colArray);
			}
			
			for each(cell in selectedCells)
			{
				for(i = cell.gridRowIndex ; i <= cell.gridRowIndex + cell.gridRowSpan - 1; i++)
				{
					for(j = cell.gridColIndex ; j <= cell.gridColIndex + cell.gridColSpan - 1; j++)
					{
						rowArray[i - minRowIndex][j - minColIndex] = 1;
					}
				}
			}
			
			for each(var arr:Array in rowArray)
			{
				if(arr.indexOf(0) != -1)
				{
					return false;
				}
			}
			
			return true;
		}
		
		private function get allowSplit():Boolean
		{
			if(selectedCells.length != 1)
			{
				return false;
			}
			
			if(Cell(selectedCells.getItemAt(0)).gridColSpan == 1)
			{
				return false;
			}			
			return true;
		}
		
		private function get allowDeleteColumn():Boolean
		{
			var colIndex:int = 0;
			for each(var row:Row in getChildren())
			{
				for each(var cell:Cell in row.getChildren())
				{
					if(cell.gridColIndex != colIndex)
					{
						return true;
					}
				}
			}
			return false;
		} 
		
		private var insertionArgs:Object;
		
		private function get allowInsertColumnLeft():Boolean
		{
			var rowInfos:Object = new Object();
			var cellInfos:Object;
			var cellInfo:Object;
			var obj:Object;
			var row:Row ;
			var cell:Cell;
			var i:int;
			var j:int;
			
			for each(row in rows.sortOn("position", Array.NUMERIC))
			{
				cellInfos = new Object();
				rowInfos[row] = cellInfos;
				cellInfos.gridRowIndex = row.gridRowIndex;
				cellInfos.distributed = false; 
			}
			
			var tmpCells:Array = sortOnWithNamespace(cells,"gridColIndex", table_internal,Array.NUMERIC);
			for(i = 0; i < tmpCells.length ; i++)
			{
				cell = Cell(tmpCells[i]);
				
				for(j = 0; j < cell.rows.length ; j++)
				{
					row = Row(cell.rows[j]);
				
					cellInfos = rowInfos[row];
	
					cellInfo = new Object();
					cellInfos[cell] = cellInfo;
					
					cellInfo.gridRowIndex = cell.gridRowIndex;
					cellInfo.gridColIndex = cell.gridColIndex;
					cellInfo.width = cell.width;
				}
			}
						
			// get the lefmost cells from selected cells.
			var leftSelectedCells:Array = new Array();
			var gridRowIndex:int = -1;
			
			tmpCells = sortOnWithNamespace(selectedCells.source,"gridColIndex", table_internal,Array.NUMERIC);
			
			for(i = 0; i < tmpCells.length ; i++)
			{
				cell = Cell(tmpCells[i]);
				
				if(gridRowIndex != cell.gridRowIndex)
				{
					leftSelectedCells.push(cell);
					gridRowIndex == cell.gridRowIndex;
				}
			}
			
			//get the sample cell we clone which as new cell to be inserted.
			var targetCell:Cell = Cell(sortOnWithNamespace(leftSelectedCells,"gridRowIndex",table_internal, Array.NUMERIC)[0]);
			var targetRow:Row = Row(targetCell.parent);
					
			// calculate the width of the targetCell after insertion.
			var totalWidth:Number = originWidth;
			var originalTargetWidth:Number = targetCell.width;
			var totalWidthAfterInsertion:Number = originWidth + originalTargetWidth; 			
			var targetWidth:Number = 0;																	
			
			// distribute the width of each cell in a row to make sure the width of the 
			// row after insertion is the same as the originWidth 			
			
			var allDistributed:Boolean = false;
			while(!allDistributed)
			{
				for each(row in rows)
				{
					cellInfos = rowInfos[row];
					if(cellInfos.distributed)
					{
						continue;
					}
					
					if(row != targetRow && targetWidth == 0)
					{
						continue;
					}
					
					var widthToDistribute:Number = totalWidth;
					var widthToDistributeAfterInsertion:Number = totalWidthAfterInsertion;
					var childrenToAdjustWidth:Array = new Array();
					
					for each(obj in cellInfos)
					{
						if(obj is Number || obj is Boolean)
						{
							continue;
						}
						cellInfo = obj;
						
						if(cellInfo.width > CellConst.MIN_WIDTH)
						{
							childrenToAdjustWidth.push(cellInfo);
						}
						else if(cellInfo.width == CellConst.MIN_WIDTH)
						{
							if(cellInfo.gridRowIndex == targetCell.gridRowIndex && cellInfo.gridColIndex == targetCell.gridColIndex)
							{
								targetWidth = cellInfo.width;
							}
							widthToDistribute -= CellConst.MIN_WIDTH;
							widthToDistributeAfterInsertion -= CellConst.MIN_WIDTH;
						}																		
					}
					 
					for each(cellInfo in childrenToAdjustWidth)
					{
						cellInfo.width = Math.floor(cellInfo.width * widthToDistribute / widthToDistributeAfterInsertion );
						if(cellInfo.width < CellConst.MIN_WIDTH)
						{ 
							cellInfo.width = CellConst.MIN_WIDTH; 
						}
						 
						if(cellInfo.gridRowIndex == targetCell.gridRowIndex && cellInfo.gridColIndex == targetCell.gridColIndex)
						{
							targetWidth = cellInfo.width;
						}
					}
					
					childrenToAdjustWidth = new Array();
					var distributedWidth:Number = targetWidth;
					for each(obj in cellInfos)
					{
						if(obj is Number || obj is Boolean)
						{
							continue;
						}
						cellInfo = obj;
						distributedWidth += cellInfo.width;
						childrenToAdjustWidth.push(obj);																													
					}
					
					var difference:Number = distributedWidth - totalWidth;
					var originDifference:Number;
					
					childrenToAdjustWidth = childrenToAdjustWidth.sortOn("gridColIndex",Array.NUMERIC);					
					while(difference > 0)
					{
						originDifference = difference;
						for each(cellInfo in childrenToAdjustWidth)
						{
							if(difference == 0)
							{
								break;
							}
							
							if(cellInfo.width > CellConst.MIN_WIDTH)
							{
								cellInfo.width --;
								difference --;
							}
						} 
						
						if(originDifference == difference)
						{
							break;
						}
					}					
					
					if(row == targetRow && difference > 0 && targetWidth > CellConst.MIN_WIDTH)
					{
						if(targetWidth - difference >= CellConst.MIN_WIDTH)
						{
							targetWidth -= difference;
							difference -= difference;
						}
						else
						{
							difference -= targetWidth - CellConst.MIN_WIDTH;
							targetWidth = CellConst.MIN_WIDTH;
						}
					}
					
					while(difference < 0)
					{
						originDifference = difference;
						for each(cellInfo in childrenToAdjustWidth)
						{
							if(difference == 0)
							{
								break;
							}
							
							cellInfo.width ++;
							difference ++;
						}						 
					}
					
					if(row == targetRow && difference < 0 )
					{
						targetWidth += Math.abs(difference);
						difference = 0; 
					}
					
					cellInfos.distributed = true;
					
					if(difference > 0)
					{
						return false;
					}
				}
				
				// judge if the width of all the cells in the row are distributed. 
				var find:Boolean = false;
				for each(row in rows)
				{
					cellInfos = rowInfos[row];			
					if(cellInfos.distributed == false)
					{
						find = true;
						break;
					}
				}
				
				if(!find)
				{
					allDistributed = true;
				}				
				else
				{
					allDistributed = false;
				}
			}			
			
			if(insertionArgs == null)
			{
				insertionArgs = new Object();
			}
			
			insertionArgs.rowInfos = rowInfos;
			insertionArgs.targetWidth = targetWidth;
			insertionArgs.targetCell = targetCell;
			return true;
		}
		
		private function get allowInsertColumnRight():Boolean
		{
			var rowInfos:Object = new Object();
			var cellInfos:Object;
			var cellInfo:Object;
			var obj:Object;
			var row:Row ;
			var cell:Cell;
			
			for each(row in sortOnWithNamespace(rows,"gridRowIndex", table_internal, Array.NUMERIC))
			{
				cellInfos = new Object();
				rowInfos[row] = cellInfos;
				cellInfos.gridRowIndex = row.gridRowIndex;
				cellInfos.distributed = false; 
			}
			
			for each(cell in sortOnWithNamespace(cells,"gridColIndex", table_internal,Array.NUMERIC))
			{				
				for each(row in cell.rows)
				{
					cellInfos = rowInfos[row];
	
					cellInfo = new Object();
					cellInfos[cell] = cellInfo;
					
					cellInfo.gridRowIndex = cell.gridRowIndex;
					cellInfo.gridColIndex = cell.gridColIndex;
					cellInfo.width = cell.width;
				}
			}
						
			// get the rightmost cells from selected cells.
			var rightSelectedCells:Array = new Array();
			var rowIndex:int = -1;
			for each(cell in sortOnWithNamespace(selectedCells.source,"gridColIndex", table_internal,Array.NUMERIC|Array.DESCENDING));
			{
				if(rowIndex != cell.gridRowIndex)
				{
					rightSelectedCells.push(cell);
					rowIndex == cell.gridRowIndex;
				}
			}
			
			//get the sample cell we clone which as new cell to be inserted.
			var targetCell:Cell = Cell(sortOnWithNamespace(rightSelectedCells,"gridRowIndex",table_internal,Array.NUMERIC)[0]);
			var targetRow:Row = Row(targetCell.parent);
					
			// calculate the width of the targetCell after insertion.
			var totalWidth:Number = originWidth;
			var originalTargetWidth:Number = targetCell.width;
			var totalWidthAfterInsertion:Number = originWidth + originalTargetWidth; 			
			var targetWidth:Number = 0;																	
			
			// distribute the width of each cell in a row to make sure the width of the 
			// row after insertion is the same as the originWidth 			
			
			var allDistributed:Boolean = false;
			while(!allDistributed)
			{
				for each(row in rows)
				{
					cellInfos = rowInfos[row];
					if(cellInfos.distributed)
					{
						continue;
					}
					
					if(row != targetRow && targetWidth == 0)
					{
						continue;
					}
					
					var widthToDistribute:Number = totalWidth;
					var widthToDistributeAfterInsertion:Number = totalWidthAfterInsertion;
					var childrenToAdjustWidth:Array = new Array();
					
					for each(obj in cellInfos)
					{
						if(obj is Number || obj is Boolean)
						{
							continue;
						}
						cellInfo = obj;
						
						if(cellInfo.width > CellConst.MIN_WIDTH)
						{
							childrenToAdjustWidth.push(cellInfo);
						}
						else if(cellInfo.width == CellConst.MIN_WIDTH)
						{
							if(cellInfo.gridRowIndex == targetCell.gridRowIndex && cellInfo.gridColIndex == targetCell.gridColIndex)
							{
								targetWidth = cellInfo.width;
							}
							widthToDistribute -= CellConst.MIN_WIDTH;
							widthToDistributeAfterInsertion -= CellConst.MIN_WIDTH;
						}																		
					}
					 
					for each(cellInfo in childrenToAdjustWidth)
					{
						cellInfo.width = Math.floor(cellInfo.width * widthToDistribute / widthToDistributeAfterInsertion );
						if(cellInfo.width < CellConst.MIN_WIDTH)
						{ 
							cellInfo.width = CellConst.MIN_WIDTH; 
						}
						 
						if(cellInfo.gridRowIndex == targetCell.gridRowIndex && cellInfo.gridColIndex == targetCell.gridColIndex)
						{
							targetWidth = cellInfo.width;
						}
					}
					
					childrenToAdjustWidth = new Array();
					var distributedWidth:Number = targetWidth;
					for each(obj in cellInfos)
					{
						if(obj is Number || obj is Boolean)
						{
							continue;
						}
						cellInfo = obj;
						distributedWidth += cellInfo.width;
						childrenToAdjustWidth.push(obj);																													
					}
					
					var difference:Number = distributedWidth - totalWidth;
					var originDifference:Number;
					
					childrenToAdjustWidth = childrenToAdjustWidth.sortOn("gridColIndex", Array.NUMERIC);					
					while(difference > 0)
					{
						originDifference = difference;
						for each(cellInfo in childrenToAdjustWidth)
						{
							if(difference == 0)
							{
								break;
							}
							
							if(cellInfo.width > CellConst.MIN_WIDTH)
							{
								cellInfo.width --;
								difference --;
							}
						} 
						
						if(originDifference == difference)
						{
							break;
						}
					}					
					
					if(row == targetRow && difference > 0 && targetWidth > CellConst.MIN_WIDTH)
					{
						if(targetWidth - difference >= CellConst.MIN_WIDTH)
						{
							targetWidth -= difference;
							difference -= difference;
						}
						else
						{
							difference -= targetWidth - CellConst.MIN_WIDTH;
							targetWidth = CellConst.MIN_WIDTH;
						}
					}
					
					while(difference < 0)
					{
						originDifference = difference;
						for each(cellInfo in childrenToAdjustWidth)
						{
							if(difference == 0)
							{
								break;
							}
							
							cellInfo.width ++;
							difference ++;
						}						 
					}
					
					if(row == targetRow && difference < 0 )
					{
						targetWidth += Math.abs(difference);
						difference = 0; 
					}
					
					cellInfos.distributed = true;
					
					if(difference > 0)
					{
						return false;
					}
				}
				
				// judge if the width of all the cells in the row are distributed. 
				var find:Boolean = false;
				for each(row in rows)
				{
					cellInfos = rowInfos[row];			
					if(cellInfos.distributed == false)
					{
						find = true;
						break;
					}
				}
				
				if(!find)
				{
					allDistributed = true;
				}				
				else
				{
					allDistributed = false;
				}
			}
			
			if(insertionArgs == null)
			{
				insertionArgs = new Object();
			}
			
			insertionArgs.rowInfos = rowInfos;
			insertionArgs.targetWidth = targetWidth;
			insertionArgs.targetCell = targetCell;
			return true;
		} 
		
		private function get allowDeleteRow():Boolean
		{
			if(getChildren().length == 1)
			{
				return false;
			}
			var targetCells:Array = selectedCells.source;	
			var targetRows:Array = new Array();		
			var cell:Cell;	
				
			for each(cell in targetCells)
			{
				if(targetRows.indexOf(cell.parent) == -1)
				{
					targetRows.push(cell.parent);
				}
			}
			targetRows = sortOnWithNamespace(targetRows,"gridRowIndex",table_internal,Array.NUMERIC);
			
			if(targetRows.length == numChildren)
			{
				return false;
			}
			return true;
		} 
		
		private function get allowInsertRow():Boolean
		{
			return true;
		} 
		
		//0:no line is being drawn.
		//1: drawing horizontal line.
		//2: drawing vertical line
		private var lineDrawingDirection:int = 0;
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			Application.application.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
					
			addEventListener(MouseEvent.MOUSE_OUT,mouseOutHandler);	
			
			addEventListener(FlexEvent.REMOVE,removeHandler);			
			
			addEventListener(EndChangeCellWidthEvent.END_CHANGE_CELL_WIDTH,endChangeCellWidthHandler);
			addEventListener(EndChangeColumnWidthEvent.END_CHANGE_COLUMN_WIDTH,endChangeColumnWidthHandler);
			addEventListener(EndChangeRowHeightEvent.END_CHANGE_ROW_HEIGHT,endChangeRowHeightHandler);
			
			addEventListener(SelectCellEvent.SELECT_CELL,selectCellHandler);
			addEventListener(SelectColumnEvent.SELECT_COLUMN,selectColumnHandler);			
			addEventListener(SelectRowEvent.SELECT_ROW,selectRowHandler);	
			
			addEventListener(StartChangeCellWidthEvent.START_CHANGE_CELL_WIDTH,startChangeCellWidthHandler);
			addEventListener(StartChangeRowHeightEvent.START_CHANGE_ROW_HEIGHT,startChangeRowHeightHandler);
		
			addEventListener(RightClickManager.RIGHT_CLICK,rightClickHandler);						
		}
		
		override protected function measure():void
		{
			super.measure();
		}
		
		override protected function commitProperties():void
		{		
			// this makes the borders of talbe cells
			// looks like 1 pixel wide	
			setStyle("horizontalGap",0);
			setStyle("verticalGap",0);
			
			super.commitProperties();
		}
		
		table_internal function updateCursor():void
		{
			if(dragging)
			{
				return ;
			}
			
			switch(cursorState)
			{
				case CursorState.NORMAL:
					cursorManager.removeAllCursors();
					break;
				case CursorState.CHANGE_COLUMN_WIDTH:
					cursorManager.setCursor(Cursor.CHANGE_COLUMN_WIDTH,2,-9,0);
					break;
				case CursorState.CHANGE_ROW_HEIGHT:
					cursorManager.setCursor(Cursor.CHANGE_ROW_HEIGHT,2,0,-9);
					break;
				case CursorState.SELECT_CELL:
					cursorManager.setCursor(Cursor.SELECT_CELL,2,-12,0);
					break;
				case CursorState.SELECT_COLUMN:
					cursorManager.setCursor(Cursor.SELECT_COLUMN,2,0,-12);
					break;					
			}
		}
		
		private function mouseUpHandler(event:MouseEvent):void
		{
			if(dragging)
			{
				if(lineDrawingDirection == 1)
				{
					dispatchEvent(new EndChangeRowHeightEvent());
				}
				else if(lineDrawingDirection == 2)
				{
					var leftCell:Cell ;
					var rightCell:Cell;
					var count:int = 0;		
					var cell:Cell;			
					var minRowIndex:int = int.MAX_VALUE;
					var maxRowIndex:int = 0;
					
					leftCell = draggingSource.leftCell;
					rightCell = draggingSource.rightCell;

					var changingCellWidth:Boolean = false;
					
					if(selectedCells.contains(leftCell))
					{
						// check if the left cell is spanned by the right cells
						for each( cell in selectedCells)
						{
							if(cell.gridColIndex + cell.gridColSpan  == leftCell.gridColIndex + leftCell.gridColSpan)
							{
								minRowIndex = Math.min(minRowIndex,cell.gridRowIndex);
								maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex + cell.gridRowSpan);
							}
						}
						
						for each(cell in cells)
						{
							if(cell.gridColIndex == leftCell.gridColIndex + leftCell.gridColSpan)
							{
								if(cell.gridRowIndex == minRowIndex)
								{
									count ++;
								}
								
								if(cell.gridRowIndex + cell.gridRowSpan == maxRowIndex)
								{
									count ++;
								}
								
								if(count == 2)
								{
									break;
								}
							}
						}																	
					}					
					else if(selectedCells.contains(rightCell))
					{
					 	// check if the right cell is spanned by the left cells
					 	for each( cell in selectedCells)
						{
							if(cell.gridColIndex == rightCell.gridColIndex)
							{
								minRowIndex = Math.min(minRowIndex,cell.gridRowIndex);
								maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex + cell.gridRowSpan);
							}
						}
						for each(cell in cells)
						{
							if(cell.gridColIndex + cell.gridColSpan == rightCell.gridColIndex)
							{
								if(cell.gridRowIndex == minRowIndex)
								{
									count ++;
								}
								
								if(cell.gridRowIndex + cell.gridRowSpan == maxRowIndex)
								{
									count ++;
								}
								
								if(count == 2)
								{
									break;
								}
							}
						}
					}

					changingCellWidth = count == 2;
					
					if(changingCellWidth)
					{
						dispatchEvent(new EndChangeCellWidthEvent());
					}
					else
					{
						dispatchEvent(new EndChangeColumnWidthEvent());
					}
				}
			}
		}
		
		private function mouseOutHandler(event:MouseEvent):void
		{
			if(!dragging)
				cursorManager.removeAllCursors();
		}
		
		private function removeHandler(event:Event):void
		{
			Application.application.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
		}
		
		private function endChangeCellWidthHandler(event:EndChangeCellWidthEvent):void
		{
			//do clear
			dragging = false;
			graphics.clear();
			cursorManager.removeAllCursors();
			removeEventListener(Event.ENTER_FRAME,drawVerticalLine);
			lineDrawingDirection = 0;
			
			// adjust the related cells' width and colSpan
			
			var targetLeftCell:Cell ;
			var targetRightCell:Cell;
			
			var leftLimitedPosition:Number;
			var rightLimitedPosition:Number;
			
			var leftCells:Array = new Array();
			var rightCells:Array = new Array();
			var cell:Cell;
			
			var minRowIndex:int = int.MAX_VALUE;
			var maxRowIndex:int = 0;
			
			targetLeftCell = draggingSource.leftCell;
			targetRightCell = draggingSource.rightCell;
			
			leftLimitedPosition = targetLeftCell.topLeftX;
			rightLimitedPosition = targetRightCell.topRightX;
			
			if(selectedCells.contains(targetLeftCell))
			{
				for each( cell in selectedCells)
				{
					if(cell.gridColIndex + cell.gridColSpan  == targetLeftCell.gridColIndex + targetLeftCell.gridColSpan)
					{
						minRowIndex = Math.min(minRowIndex,cell.gridRowIndex);
						maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex + cell.gridRowSpan);
					}
				}
				
				for each(cell in cells)
				{
					if(cell.gridRowIndex >= minRowIndex && cell.gridRowIndex + cell.gridRowSpan <= maxRowIndex)
					{
						if(cell.gridColIndex + cell.gridColSpan == targetLeftCell.gridColIndex + targetLeftCell.gridColSpan)
						{
							leftCells.push(cell);
						}
						
						if(cell.gridColIndex == targetLeftCell.gridColIndex + targetLeftCell.gridColSpan )
						{
							rightCells.push(cell);
						}
					}
				}
			}
			else if(selectedCells.contains(targetRightCell))
			{
				for each( cell in selectedCells)
				{
					if(cell.gridColIndex  == targetRightCell.gridColIndex)
					{
						minRowIndex = Math.min(minRowIndex,cell.gridRowIndex);
						maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex + cell.gridRowSpan);
					}
				}
				
				for each(cell in cells)
				{
					if(cell.gridRowIndex >= minRowIndex && cell.gridRowIndex + cell.gridRowSpan <= maxRowIndex)
					{
						if(cell.gridColIndex + cell.gridColSpan == targetRightCell.gridColIndex)
						{
							leftCells.push(cell);
						}
						
						if(cell.gridColIndex == targetRightCell.gridColIndex )
						{
							rightCells.push(cell);
						}		            	
					}
				}
			}
			
			for each(cell in leftCells)
			{
				cell.width = draggingDropPosition - leftLimitedPosition;
			    cell.gridColSpan = int(cell.width / CellConst.BASIC_WIDTH);
			}
			
			for each(cell in rightCells)
			{
				cell.width += cell.x - draggingDropPosition;
			    cell.gridColSpan = int(cell.width / CellConst.BASIC_WIDTH);
			}									

			// clear the draggingSource object
			draggingSource = null;
		}
		
		private function endChangeColumnWidthHandler(event:EndChangeColumnWidthEvent):void
		{
			//do clear
			dragging = false;
			graphics.clear();
			cursorManager.removeAllCursors();
			removeEventListener(Event.ENTER_FRAME,drawVerticalLine);	
			lineDrawingDirection = 0;
			
			// adjust the related cells' width and colSpan							
			
			var leftLimitedPosition:Number;
			var rightLimitedPosition:Number;
			
			var targetLeftCell:Cell ;
			var targetRightCell:Cell;
			
			targetLeftCell = draggingSource.leftCell;
			targetRightCell = draggingSource.rightCell;
			
			leftLimitedPosition = targetLeftCell.topLeftX;
			rightLimitedPosition = targetRightCell.topRightX;
			
			var leftCells:Array = new Array();
			var rightCells:Array = new Array();
			var cell:Cell;
			
			// fix the width and colSpan cell by cell
			for each(cell in cells)
			{
				if(cell.gridColIndex + cell.gridColSpan == targetLeftCell.gridColIndex + targetLeftCell.gridColSpan)
				{
					leftCells.push(cell);
				}
				
				if(cell.gridColIndex == targetRightCell.gridColIndex)
				{
					rightCells.push(cell);							
				}
			}	
			
			for each(cell in leftCells)
			{
				cell.width = draggingDropPosition - cell.x;
			    cell.gridColSpan = int(cell.width / CellConst.BASIC_WIDTH);
			}
			
			for each(cell in rightCells)
			{
				cell.width += cell.x - draggingDropPosition;
			    cell.gridColSpan = int(cell.width / CellConst.BASIC_WIDTH);
			}
			
			// clear the draggingSource object
			draggingSource = null;				
		}
		
		private function endChangeRowHeightHandler(event:EndChangeRowHeightEvent):void
		{
			//do clear			
			dragging = false;
			graphics.clear();
			cursorManager.removeAllCursors();
			removeEventListener(Event.ENTER_FRAME,drawHorizontalLine);
			lineDrawingDirection = 0;
			
			// adjust the related row's height
			
			var targetCell:Cell = Cell(draggingSource);
		    var targetRow:Row = Row(targetCell.parent);			
			var lastSpannedRowIndex:int;
			var minRowSpan:int = int.MAX_VALUE;
			var cell:Cell;	
			var maxRowIndex:int = 0;
			var targetRows:Array = new Array();
			var targetCells:Array = new Array();
					
			lastSpannedRowIndex = targetRow.gridRowIndex + targetCell.gridRowSpan - 1;			
			
			for each(cell in cells)
			{
				if(cell.gridRowIndex > lastSpannedRowIndex)
				{
					continue;
				}
				if(cell.gridRowIndex + cell.gridRowSpan - 1 >= lastSpannedRowIndex)
				{
					targetCells.push(cell);					
					if(targetRows.indexOf(cell) == -1)
					{
						targetRows.push(cell.parent);
						maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex);
					}
				}
			}
			
			var row:Row;
			
			for each(row in targetRows)
			{
				if(row.gridRowIndex == maxRowIndex)
				{
					targetRow = row;
				}
			}
			
			if(draggingDropPosition < targetRow.y + CellConst.MIN_HEIGHT)
			{
				draggingDropPosition = targetRow.y + CellConst.MIN_HEIGHT;
			}			
						
			var targetSpan:int;
			var targetHeight:Number;
						
			targetHeight = draggingDropPosition - (targetRow.y + targetRow.height);
			targetSpan = int( targetHeight / CellConst.BASIC_HEIGHT);
			
			targetRow.height += targetHeight;
			
			for each(cell in targetCells)
			{
				cell.gridRowSpan += targetSpan;
			}
			
			// clear the draggingSource object
			draggingSource = null;
		}
		
		private function selectCellHandler(event:SelectCellEvent):void
		{
			var ctrlKey:Boolean = event.ctrlKey;
			var shiftKey:Boolean = event.shiftKey;
			var targetCell:Cell = event.targetCell;
			
			if(!ctrlKey && ! shiftKey)
			{
				clearSelectedCells(); 
			}
			
			if(ctrlKey && shiftKey)
			{
				shiftKey = false;
			}
			
			if(shiftKey)
			{
				if(selectedCells.length > 0 && lastSelectedCellBeforePressShiftKey == null)
				{
					lastSelectedCellBeforePressShiftKey = Cell(selectedCells.getItemAt(selectedCells.length-1));
				}	
				
				if(!lastSelectedCellBeforePressShiftKey)
				{
					lastSelectedCellBeforePressShiftKey = targetCell;	
				}
				
				if(selectedCells.length > 0)
				{					
					clearSelectedCells();	
					
					if(!lastSelectedCellBeforePressShiftKey.parent || !targetCell.parent)
					{
						return;
					}

					var maxRowIndex:int = Math.max( lastSelectedCellBeforePressShiftKey.gridRowIndex,
													targetCell.gridRowIndex,
												    lastSelectedCellBeforePressShiftKey.gridRowIndex + lastSelectedCellBeforePressShiftKey.gridRowSpan - 1,
													targetCell.gridRowIndex + targetCell.gridRowSpan - 1);
													
		            var minRowIndex:int = Math.min( lastSelectedCellBeforePressShiftKey.gridRowIndex,
		            								targetCell.gridRowIndex,
												    lastSelectedCellBeforePressShiftKey.gridRowIndex + lastSelectedCellBeforePressShiftKey.gridRowSpan - 1,
													targetCell.gridRowIndex + targetCell.gridRowSpan - 1);
													
		            var maxColIndex:int = Math.max( lastSelectedCellBeforePressShiftKey.gridColIndex,
		            								targetCell.gridColIndex,
		            								lastSelectedCellBeforePressShiftKey.gridColIndex + lastSelectedCellBeforePressShiftKey.gridColSpan -1,
		            								targetCell.gridColIndex + targetCell.gridColSpan - 1);           
		            								    
		            var minColIndex:int = Math.min( lastSelectedCellBeforePressShiftKey.gridColIndex,
		            								targetCell.gridColIndex,
		            								lastSelectedCellBeforePressShiftKey.gridColIndex + lastSelectedCellBeforePressShiftKey.gridColSpan -1,
		            								targetCell.gridColIndex + targetCell.gridColSpan - 1); 
		            
		            // check if the cell should be selected
		            for each(var cell:Cell in cells)	
		            {
		            	if(cell.gridColIndex + cell.gridColSpan - 1 < minColIndex)
		            	{
		            		continue;
		            	}
		            	
		            	if(cell.gridColIndex > maxColIndex)
		            	{
		            		continue;
		            	}	
		            	
		            	if(cell.gridRowIndex + cell.gridRowSpan - 1 < minRowIndex)
		            	{
		            		continue;
		            	}
		            	
		            	if(cell.gridRowIndex > maxRowIndex)
		            	{
		            		continue;
		            	}
		            	
		            	selectCell(cell);		            		            	
		            }
		            return;			            			
				}
			}
			else
			{
				lastSelectedCellBeforePressShiftKey = null; 
			}
			
			selectCell(event.targetCell);	
		}
		
		private function selectCell(cell:Cell):void
		{
			if(!selectedCells.contains(cell))
			{
				cell.table_internal::selected = true;
				selectedCells.addItem(cell);
			}
			else
			{
				cell.table_internal::selected = false;
				selectedCells.removeItemAt(selectedCells.getItemIndex(cell));
			}
			
		}
		
		private function selectColumnHandler(event:SelectColumnEvent):void
		{
			var ctrlKey:Boolean = event.ctrlKey;
			var shiftKey:Boolean = event.shiftKey;
			var colIndex:int = event.targetColumnIndex;
			
			var currentColumnFirstCell:Cell = getCell(0,colIndex);
							
			
			
			var maxColIndex:int = Math.max( currentColumnFirstCell.gridColIndex,
											currentColumnFirstCell.gridColIndex + currentColumnFirstCell.gridColSpan -1 );
											
			var minColIndex:int = Math.min( currentColumnFirstCell.gridColIndex,
											currentColumnFirstCell.gridColIndex + currentColumnFirstCell.gridColSpan -1 );
			
			if(!ctrlKey && !shiftKey)
			{
				clearSelectedCells();
			}
			
			if(ctrlKey && shiftKey)
			{
				shiftKey = false;
			}
			
			if(shiftKey)
			{
				if(selectedColumns.length > 0 && lastSelectedColumnIndexBeforePresShiftKey == -1)
				{
					lastSelectedColumnIndexBeforePresShiftKey = selectedColumns[selectedColumns.length - 1];
				}
				
				if(lastSelectedColumnIndexBeforePresShiftKey == -1)
				{
					lastSelectedColumnIndexBeforePresShiftKey = colIndex;	
				}

				
				if(selectedColumns.length > 0)
				{					
					clearSelectedCells();
	         		
	         		var lastColumnFirstCell:Cell = getCell(0,lastSelectedColumnIndexBeforePresShiftKey);
	         		
		         	maxColIndex = Math.max( lastColumnFirstCell.gridColIndex,
         									lastColumnFirstCell.gridColIndex + lastColumnFirstCell.gridColSpan - 1,
         									currentColumnFirstCell.gridColIndex,
         									currentColumnFirstCell.gridColIndex + currentColumnFirstCell.gridColSpan -1);
		         									
		         	minColIndex = Math.min( lastColumnFirstCell.gridColIndex,
         									lastColumnFirstCell.gridColIndex + lastColumnFirstCell.gridColSpan - 1,
         									currentColumnFirstCell.gridColIndex,
         									currentColumnFirstCell.gridColIndex + currentColumnFirstCell.gridColSpan -1);								         					
				}				
			}
			else
			{
				lastSelectedColumnIndexBeforePresShiftKey = -1;
			}			
			
			if(selectedColumns.indexOf(colIndex) == -1)
			{
				selectedColumns.push(colIndex);
				for each(var cell:Cell in cells)
	         	{
	         		if(cell.gridColIndex + cell.gridColSpan - 1 < minColIndex)
	         		{
	         			continue;
	         		}
	         		if(cell.gridColIndex > maxColIndex)
	         		{
	         			continue;
	         		}
	         		selectCell(cell);
	         	}
   			}
		}
		
		private function selectRowHandler(event:SelectRowEvent):void
		{
			clearSelectedCells();
			var row:Row = event.targetRow;
			for each(var cell:Cell in row.getChildren())
			{
				cell.table_internal::selected = true;
				if(!selectedCells.contains(cell))
				{
					selectedCells.addItem(cell);
				}
			}
		}
		
		private function clearSelectedCells():void
		{
			for each(var cell:Cell in selectedCells)
			{
				cell.table_internal::selected = false;
			}
			
			selectedCells.removeAll();
			
			if(selectedColumns)
			{ 
				selectedColumns = null;
				selectedColumns = new Array();
			}			
		}
		
		private function startChangeCellWidthHandler(event:StartChangeCellWidthEvent):void
		{
			draggingSource = new Object();
			draggingSource.leftCell = event.leftCell;
			draggingSource.rightCell = event.rightCell;
			draggingSource.targetRow = event.targetRow;
			dragging = true;
			lineDrawingDirection = 2;			
			addEventListener(Event.ENTER_FRAME,drawVerticalLine);	
		}
		
		// when changing the width of a cell or a column , we drag the vertical line
		// represent the border of the cell or the column to a position which is limited
		// in a specified area and release the mouse button to move the boder to the position. 
		// The changing of the border position means the changing of width.
		private function drawVerticalLine(event:Event):void
		{		
			//1. calculate the specified area where the indicating line is able to be moved to.
			
			// the border line is shared by tow cells. moving the border means
			// changing the width of the two cells and the other releated cells.
			// clear the former line	
			//        [border]	
			//            |
			// [leftCell] | [rightCell]		
			//            |
				
			var leftCell:Cell ;
			var rightCell:Cell;
			var leftLimitedPosition:Number;
			var rightLimitedPosition:Number;
			var cell:Cell;
			leftCell = draggingSource.leftCell;
			rightCell = draggingSource.rightCell;
		
			var leftCells:Array = new Array();
			var rightCells:Array = new Array();
			var minLeftCellColSpan:int = int.MAX_VALUE;
			var minRightCellColSpan:int = int.MAX_VALUE;
			
			for each(cell in cells)
			{
				if(cell.gridColIndex + cell.gridColSpan == leftCell.gridColIndex + leftCell.gridColSpan)
				{
					minLeftCellColSpan = Math.min(minLeftCellColSpan,cell.gridColSpan);
					leftCells.push(cell);
				}
				if(cell.gridColIndex == rightCell.gridColIndex)
				{
					minRightCellColSpan = Math.min(minRightCellColSpan,cell.gridColSpan);
					rightCells.push(cell);
				}
			}
			
			for each(cell in leftCells)
			{
				if(cell.gridColSpan == minLeftCellColSpan)
				{
					leftLimitedPosition = cell.topLeftX;
					break;
				}
			}
			
			for each(cell in rightCells)
			{
				if(cell.gridColSpan == minRightCellColSpan)
				{
					rightLimitedPosition = cell.topRightX;
					break;
				}
			}
			
						
			if(selectedCells.contains(leftCell))
			{
				rightLimitedPosition = rightCell.topRightX;
				leftLimitedPosition = leftCell.topLeftX;
			}
			
			if(selectedCells.contains(rightCell))
			{
				rightLimitedPosition = rightCell.topRightX;
				leftLimitedPosition = leftCell.topLeftX;
			}
			
			var position:Number = mouseX;
			// there is a limit to the width of cell
			if(position < leftLimitedPosition + CellConst.MIN_WIDTH)
			{
				position = leftLimitedPosition + CellConst.MIN_WIDTH;
			}
			if(position > rightLimitedPosition - CellConst.MIN_WIDTH)
			{
				position = rightLimitedPosition - CellConst.MIN_WIDTH;
			}
			
			// we use the DEFAULT_WIDTH of cell as the basic unit to change the width of cells.
			position = leftLimitedPosition + Math.ceil((position - leftLimitedPosition) / CellConst.BASIC_WIDTH) * CellConst.BASIC_WIDTH;
			
			// before we transform the position into the global coordinates system
			// we remember this position to change the  width of the cell or the 
			// column.
			draggingDropPosition = position;
					
			//2. start to draw the line.
			
			var lineLength:Number = height;
			var count:int;
			
			// we should clear the former line before draw the new line
			graphics.clear();
			graphics.lineStyle(1);
			
			graphics.beginFill(0x000000,0.8);
			// draw a dotted line
			for(var len:Number = 0; len < lineLength ; )
			{
				graphics.moveTo(position,len);
				graphics.lineTo(position,len+1);
				if(count < 3)
				{
					count ++;
					len+=2;
				}
				if(count == 3)
				{
					count = 0;
					len+=4;
				}
			}
			graphics.endFill();								
		}
		
		private function startChangeRowHeightHandler(event:StartChangeRowHeightEvent):void
		{
			draggingSource = event.targetCell;
			dragging = true;	
			lineDrawingDirection = 1;		
			addEventListener(Event.ENTER_FRAME,drawHorizontalLine);
		}
		
		private function drawHorizontalLine(event:Event):void
		{
			//1. calculate the specified area where the indicating line is able to be moved to.
			var targetCell:Cell = Cell(draggingSource);
			var targetRow:Row = Row(targetCell.parent);
			var lastSpannedRowIndex:int;
			var cell:Cell;

			lastSpannedRowIndex = targetRow.gridRowIndex + targetCell.gridRowSpan - 1;
			
			var maxRowIndex:int = 0;
			var targetRows:Array = new Array();
			
			for each(cell in cells)
			{
				if(cell.gridRowIndex + cell.gridRowSpan - 1 == lastSpannedRowIndex)
				{
					if(targetRows.indexOf(cell) == -1)
					{
						targetRows.push(cell.parent);
						maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex);
					}
				}
			}
			
			var row:Row;
			for each(row in targetRows)
			{
				if(row.gridRowIndex == maxRowIndex)
				{
					targetRow = row;
				}
			}
			
			var position:Number = mouseY;
			var upLimitedPosition:Number = targetRow.y;
			if(position < upLimitedPosition + CellConst.PADDING_TOP)
			{
				position = upLimitedPosition + CellConst.PADDING_TOP;
			}
			position = upLimitedPosition + Math.ceil((position - upLimitedPosition) / CellConst.BASIC_WIDTH) * CellConst.BASIC_WIDTH;
			
			draggingDropPosition = position;
			//2. start to draw
			
			var lineLength:Number = width;
			var count:int = 0;
			
			// we should clear the former line before draw the new line
			graphics.clear();
			graphics.lineStyle(1);
			
			graphics.beginFill(0x000000,0.8);
			
			// draw a dotted line
			for(var len:Number = 0; len < lineLength ; )
			{
				graphics.moveTo(len,position);
				graphics.lineTo(len+1,position);
				if(count < 3)
				{
					count ++;
					len+=2;
				}
				if(count == 3)
				{
					count = 0;
					len+=4;
				}
			}
			graphics.endFill();		
		}	
		
		private	function getCell(rowIndex:int,columnIndex:int):Cell
		{
			for each(var row:Row in getChildren())
			{
				for each(var cell:Cell in row.getChildren())
				{
					if(row.gridRowIndex == rowIndex && cell.gridColIndex == columnIndex)
					{
						return cell;
					}
				}
			}
			return null;
		}
		
		private function rightClickHandler(evt:MouseEvent):void		
		{
			if(!menus)
			{
				menus = new Array(); 
			}
			var menu:Menu;
			
			// hide all the opened menus.
			for each(menu in menus)
			{
				menu.hide();
			}
			
			menu = Menu.createMenu(this, createMenuItems(), false);
			menus.push(menu);
			
            menu.labelField="label"
            
            // Add an event listener for the itemClick event.
            menu.addEventListener(MenuEvent.ITEM_CLICK, menuItemClickHandler);
            
            // Show the menu.
            var point:Point = new Point(mouseX,mouseY);
            point = localToGlobal(point); 
            menu.show(point.x,point.y);
            
            
		}
		
		private function createMenuItems():Array
		{
			var menuItems:Array = new Array();
			var menuItem:Object;
			
        	if(allowMerge)
        	{
        		menuItem = new Object();
        		menuItem.label = "Merge Cells";
        		menuItem.number = MenuConst.COMBINE_CELLS;
        		menuItems.push(menuItem);
        	}       	
        	if(allowSplit)
        	{
         		menuItem = new Object();
        		menuItem.label = "Split Cells";
        		menuItem.number = MenuConst.SPLIT_CELL;
        		menuItems.push(menuItem);       		
        	} 
        	
        	// insert column
        	if(allowInsertColumnLeft)
        	{
        		menuItem = new Object();
        		menuItem.label = "Insert Columns to the Left";
        		menuItem.number = MenuConst.INSERT_COLUMN_LEFT;
        		menuItems.push(menuItem);
        	}
        	
        	if(allowInsertColumnRight)
        	{
        		menuItem = new Object();
        		menuItem.label = "Insert Columns to the Right";
        		menuItem.number = MenuConst.INSERT_COLUMN_RIGHT;
        		menuItems.push(menuItem); 
        	}
    
        	// delete column
        	/* if(allowDeleteColumn)
        	{
        		menuItem = new Object();
        		menuItem.label = "Delete Column";
        		menuItem.number = MenuConst.DELETE_COLUMN;
        		menuItems.push(menuItem); 
        	} */
        	// insert row
        	if(allowInsertRow)
        	{
        		menuItem = new Object();
        		menuItem.label = "Insert Rows Above";
        		menuItem.number = MenuConst.INSERT_ROW_TOP;
        		menuItems.push(menuItem); 
        	}
        	if(allowInsertRow)
        	{
        		menuItem = new Object();
        		menuItem.label = "Insert Rows Below";
        		menuItem.number = MenuConst.INSERT_ROW_BOTTOM;
        		menuItems.push(menuItem); 
        	}
        	// delete row
        	if(allowDeleteRow)
        	{
        		menuItem = new Object();
        		menuItem.label = "Delete Entire Row";
        		menuItem.number = MenuConst.DELETE_ROW;
        		menuItems.push(menuItem); 
        	}
        	
        	return menuItems;
		}
		
		private function menuItemClickHandler(event:MenuEvent):void
		{
			switch(event.item.number)
			{
				case MenuConst.COMBINE_CELLS:
					mergeSelectedCells();
					break;
				case MenuConst.SPLIT_CELL:
					splitCell();
					break;
				case MenuConst.INSERT_ROW_TOP:
					insertRowTop();
					break;
				case MenuConst.INSERT_ROW_BOTTOM:
					insertRowBottom();
					break;
				case MenuConst.DELETE_ROW:
					deleteRow();
					break;
				case MenuConst.INSERT_COLUMN_LEFT:
					insertColumnLeft();
					break;
				case MenuConst.INSERT_COLUMN_RIGHT:
					insertColumnRight();
					break;
				case MenuConst.DELETE_COLUMN:
					deleteColumn();
					break;
			}
		}

		private function insertRowTop():void
		{
			var targetCells:Array = selectedCells.source;	
			var targetRows:Array = new Array();		
			var cell:Cell;	
				
			for each(cell in targetCells)
			{
				if(targetRows.indexOf(cell.parent) == -1)
				{
					targetRows.push(cell.parent);
				}
			}
			targetRows = sortOnWithNamespace(targetRows,"gridRowIndex",table_internal,Array.NUMERIC);
			
			var topRow:Row = Row(targetRows[0]);
			var topRowPosition:int = getChildIndex(topRow);

			var targetCell:Cell = sortOnWithNamespace(topRow.getChildren(),"gridRowSpan",table_internal,Array.NUMERIC)[0];
			
			for each(cell in cells)
			{
				if(cell.gridRowIndex < topRow.gridRowIndex && cell.gridRowIndex + cell.gridRowSpan >= targetCell.gridRowIndex + targetCell.gridRowSpan)
				{
					cell.gridRowSpan += targetCell.gridRowSpan * targetRows.length;
				}
			}
			var newRowPosition:int = topRowPosition;
			
			for(var i:int = 0 ; i < targetRows.length ; i++)
			{
				if(newRowPosition == -1)
				{
					newRowPosition = 0;
				}
				
				var newRow:Row = new Row();
				newRow.height = topRow.height;
				
				for each(cell in topRow.getChildren())
				{
					var newCell:Cell = new Cell();
					newCell.width = cell.width;
					newCell.gridColSpan = cell.gridColSpan;
					newCell.gridRowSpan = targetCell.gridRowSpan;
					
					newRow.addChild(newCell);
				}
				addChildAt(newRow,newRowPosition);
			}
		}
		
		private function insertRowBottom():void
		{
			var targetCells:Array = selectedCells.source;	
			var targetRows:Array = new Array();		
			var cell:Cell;
			
			for each(cell in targetCells)
			{
				if(targetRows.indexOf(cell.parent) == -1)
				{
					targetRows.push(cell.parent);
				}
			}
			targetRows = sortOnWithNamespace(targetRows,"gridRowIndex",table_internal,Array.NUMERIC);
			
			var bottomRow:Row = Row(targetRows[targetRows.length - 1]);
			var bottomRowPosition:int = getChildIndex(bottomRow);
			
			var targetCell:Cell = sortOnWithNamespace(bottomRow.getChildren(),"gridRowSpan",table_internal,Array.NUMERIC)[0];
			
			var cellsSpannedBottomRow:Array = new Array();
			for each(cell in cells)
			{
				if(cell.gridRowIndex <= bottomRow.gridRowIndex && cell.gridRowIndex + cell.gridRowSpan >= targetCell.gridRowIndex + targetCell.gridRowSpan)
				{
					if(cell.gridRowIndex + cell.gridRowSpan > targetCell.gridRowIndex + targetCell.gridRowSpan)
					{
						cell.gridRowSpan += targetCell.gridRowSpan * targetRows.length;
					}
					cellsSpannedBottomRow.push(cell);
				}
			}			
			
			var newRowPosition:int = bottomRowPosition + 1;
			var cellsToBeCreated:Array = new Array();
			
			var currentColIndex:int = 0;
			var i:int;
			
			for( i = 0; i < bottomRow.numChildren + cellsSpannedBottomRow.length ; i++)
			{
				for each(cell in bottomRow.getChildren())
				{
					if(cell.gridColIndex == currentColIndex)
					{
						cellsToBeCreated.push(cell);
						currentColIndex = cell.gridColIndex + cell.gridColSpan;
					}
				}
				
				for each(cell in cellsSpannedBottomRow)
				{
					if(cell.gridColIndex == currentColIndex)
					{						
						cellsToBeCreated.push(cell);
						currentColIndex = cell.gridColIndex + cell.gridColSpan;
					}
				}
			}
 
			for(i = 0 ; i < targetRows.length ; i++)
			{
				if(newRowPosition == -1)
				{
					newRowPosition = 0;
				}
				
				var newRow:Row = new Row();
				newRow.height = bottomRow.height;
				
				for each(cell in cellsToBeCreated)
				{
					if(cell.gridRowIndex <= bottomRow.gridRowIndex && cell.gridRowIndex + cell.gridRowSpan > targetCell.gridRowIndex + targetCell.gridRowSpan)
					{
						continue;
					}
					var newCell:Cell = new Cell();
					newCell.width = cell.width;
					newCell.gridColSpan = cell.gridColSpan;
					newCell.gridRowSpan = targetCell.gridRowSpan;
					
					newRow.addChild(newCell);
				}
				addChildAt(newRow,newRowPosition);
			}
		}
		
		private function deleteRow():void
		{
			var targetCells:Array = selectedCells.source;	
			var targetRows:Array = new Array();		
			var cell:Cell;
			var row:Row;
			
			for each(cell in targetCells)
			{
				if(targetRows.indexOf(cell.parent) == -1)
				{
					targetRows.push(cell.parent);
				}
			}
			targetRows = sortOnWithNamespace(targetRows,"gridRowIndex",table_internal,Array.NUMERIC|Array.DESCENDING);
			
			var topRow:Row = Row(targetRows[targetRows.length - 1]);
			var bottomRow:Row = Row(targetRows[0]);
			var topRowTargetCell:Cell = Cell(sortOnWithNamespace(topRow.getChildren(),"gridRowSpan",table_internal,Array.NUMERIC)[0]);
			var bottomRowTargetCell:Cell = Cell(sortOnWithNamespace(bottomRow.getChildren(),"gridRowSpan",table_internal,Array.NUMERIC)[0]);
									
			for each(cell in cells)
			{
				if(cell.gridRowIndex + cell.gridRowSpan - 1 < topRow.gridRowIndex)
				{
					continue;
				}
				
				if(cell.gridRowIndex > bottomRow.gridRowIndex + bottomRowTargetCell.gridRowSpan - 1)
				{
					continue;
				}
				
				var targetCell:Cell;
				
				if(cell.gridRowIndex < topRow.gridRowIndex && cell.gridRowIndex + cell.gridRowSpan > bottomRow.gridRowIndex + bottomRowTargetCell.gridRowSpan - 1)
				{					
					for each(row in targetRows)
					{
						targetCell = Cell(sortOnWithNamespace(row.getChildren(),"gridRowSpan",table_internal,Array.NUMERIC)[0]);
						cell.gridRowSpan -= targetCell.gridRowSpan;
					}
					continue;
				}				
				
				if(cell.gridRowIndex < topRow.gridRowIndex && cell.gridRowIndex + cell.gridRowSpan <= bottomRow.gridRowIndex + bottomRowTargetCell.gridRowSpan)
				{
					for each(row in targetRows)
					{
						targetCell = Cell(sortOnWithNamespace(row.getChildren(),"gridRowSpan",table_internal,Array.NUMERIC)[0]);						
						if(cell.gridRowIndex + cell.gridRowSpan == row.next.gridRowIndex)
						{
							cell.gridRowSpan -= targetCell.gridRowSpan;
						}
					}
					continue;
				}
				
				targetRows = sortOnWithNamespace(targetRows,"gridRowIndex",table_internal,Array.NUMERIC);
				
				if(cell.gridRowIndex >= topRow.gridRowIndex && cell.gridRowIndex + cell.gridRowSpan > bottomRow.gridRowIndex + bottomRowTargetCell.gridRowSpan)
				{
					for each(row in targetRows)
					{
						if(cell.gridRowIndex == row.gridRowIndex)
						{
							cell.gridRowSpan -= bottomRow.gridRowIndex + bottomRowTargetCell.gridRowSpan - row.gridRowIndex;
							var position:int = cell.position;
							Row(cell.parent).removeChild(cell);
							if(bottomRow.next)
							{
								bottomRow.next.addChildAt(cell,position);
							}
						}
					}
					continue;
				}
			}
			
			for each(row in targetRows)
			{
				removeChild(row);
			}
		}
		
		private function insertColumnLeft():void
		{
			var rowInfos:Object = insertionArgs.rowInfos;
			var targetWidth:Number = insertionArgs.targetWidth;
			var targetCell:Cell = insertionArgs.targetCell;
			
			var cellInfos:Object;
			var cellInfo:Object;
				
			var row:Row;
			var cell:Cell;
			
			//insert cells at specifed position
			clearSelectedCells();
			for each(cell in cells)
			{
				if(cell.gridColIndex <= targetCell.gridColIndex 
					   && cell.gridColIndex + cell.gridColSpan > targetCell.gridColIndex
					   && cell.gridColIndex + cell.gridColSpan <= targetCell.gridColIndex + targetCell.gridColSpan)
				{						
					
					for each(row in cell.rows)
					{
						var newCell:Cell = new Cell();
						newCell.gridRowSpan = row.gridRowSpan;
					 	newCell.width = targetWidth;
					 	newCell.gridColSpan = newCell.width/CellConst.BASIC_WIDTH;
					 	
					 	var position:int;
					 	
					 	var tmpCell:Cell = Cell(sortOnWithNamespace(row.getChildren(),"gridColIndex", table_internal,Array.NUMERIC)[0]);
					 	do
					 	{
						 	if(tmpCell == cell)
						 	{
						 		position = row.getChildIndex(cell);
						 		break;
						 	}
						 	
						 	if(tmpCell.gridColIndex + tmpCell.gridColSpan == cell.gridColIndex)
						 	{
						 		position = row.getChildIndex(tmpCell) + 1;						 		 
						 		break;  
						 	}
						 	
						 	tmpCell = tmpCell.next;
					 	}
					 	while(tmpCell);
					 	
					 	if(position < row.getChildren().length)
					 	{
					 		row.addChildAt(newCell,position);
					 	}
					 	else
					 	{
					 		row.addChild(newCell);
					 	}
					 	selectCell(newCell);
					}				 	
				} 
			}
			
			// set the width and colSpan of each cells after insertion.
			for each(row in rows)
			{
				for each(cell in row.getChildren())
				{
					cellInfos = rowInfos[row];
					cellInfo = cellInfos[cell];
					if(cellInfo)
					{
						cell.width = cellInfo.width;									
						cell.gridColSpan = cell.width/CellConst.BASIC_WIDTH;
					}			
				}
			} 											
		}
		
		private function insertColumnRight():void
		{
			var rowInfos:Object = insertionArgs.rowInfos;
			var targetWidth:Number = insertionArgs.targetWidth;
			var targetCell:Cell = insertionArgs.targetCell;
			
			var cellInfos:Object;
			var cellInfo:Object;
				
			var row:Row;
			var cell:Cell;
			
			//insert cells at specifed position
			clearSelectedCells();
			for each(cell in cells)
			{
				if(cell.gridColIndex + cell.gridColSpan >= targetCell.gridColIndex + targetCell.gridColSpan 
				   && cell.gridColIndex < targetCell.gridColIndex + targetCell.gridColSpan )					   
				{						
					
					for each(row in cell.rows)
					{
						var newCell:Cell = new Cell();
						newCell.gridRowSpan = row.gridRowSpan;
					 	newCell.width = targetWidth;
					 	newCell.gridColSpan = newCell.width/CellConst.BASIC_WIDTH;
					 	
					 	var position:int;
					 		
					 	var tmpCell:Cell = Cell(sortOnWithNamespace(row.getChildren(),"gridColIndex", table_internal,Array.NUMERIC)[0]);
					 	do
					 	{
						 	if(tmpCell == cell)
						 	{
						 		position = row.getChildIndex(cell) + 1;
						 		break;
						 	}
						 	
						 	if(tmpCell.gridColIndex == cell.gridColIndex + cell.gridColSpan)
						 	{
						 		position = row.getChildIndex(tmpCell);						 		 
						 		break;  
						 	}
						 	
						 	tmpCell = tmpCell.next;
					 	}
					 	while(tmpCell);
					 	
					 	if(position < row.getChildren().length)
					 	{
					 		row.addChildAt(newCell,position);
					 	}
					 	else
					 	{
					 		row.addChild(newCell);
					 	}
					 	selectCell(newCell);
					}				 	
				} 
			}
			
			// set the width and colSpan of each cells after insertion.
			for each(row in rows)
			{
				for each(cell in row.getChildren())
				{
					cellInfos = rowInfos[row];
					cellInfo = cellInfos[cell];
					if(cellInfo)
					{
						cell.width = cellInfo.width;									
						cell.gridColSpan = cell.width/CellConst.BASIC_WIDTH;
					}			
				}
			}
		}
		
		private function deleteColumn():void
		{
			
		}
		
		private function mergeSelectedCells():void
		{
			// 1.find the top-left cell of selected cells
			var minColIndex:int = int.MAX_VALUE;
			var maxColIndex:int = -1;
			var minRowIndex:int = int.MAX_VALUE;
			var maxRowIndex:int = -1;
			var cell:Cell;
			var i:int;
			
			for each(cell in selectedCells)
			{
				minColIndex = Math.min(minColIndex,cell.gridColIndex);
				maxColIndex = Math.max(maxColIndex,cell.gridColIndex + cell.gridColSpan - 1);
				
				minRowIndex = Math.min(minRowIndex,cell.gridRowIndex);
				maxRowIndex = Math.max(maxRowIndex,cell.gridRowIndex + cell.gridRowSpan - 1);
			}
			
			var topLeftCell:Cell = getCell(minRowIndex,minColIndex);
			
			// 2. correct the top-left cell's width, height and span.
			var topLeftCellHeight:Number = 0;
			for(i = minRowIndex; i <= maxRowIndex ; )
			{
				cell = getCell(i,minColIndex);
				topLeftCellHeight += cell.height;
				
				i = cell.gridRowIndex + cell.gridRowSpan;
			}
			topLeftCell.gridColSpan = maxColIndex - minColIndex + 1;
			topLeftCell.width = topLeftCell.gridColSpan * CellConst.BASIC_WIDTH;
			
			topLeftCell.gridRowSpan = maxRowIndex - minRowIndex + 1;
			topLeftCell.height = topLeftCellHeight;
			
			//3. remove the other cells
			for each(cell in selectedCells)
			{
				if(cell != topLeftCell)
				{					
					cell.parent.removeChild(cell);
				}
			}
			
			clearSelectedCells();
			
			//4. remove the rows which owns no children
			var rowToBeRemoved:Array = new Array();
			var row:Row;
			for each(row in getChildren())
			{
				if(row.numChildren == 0)
				{
					rowToBeRemoved.push(row);
				}
			}
			
			for each(row in rowToBeRemoved)
			{
				getChildAt(getChildIndex(row) - 1).height += row.height;
				removeChild(row);
			}
			
			//5. select the top-left cell
			selectCell(topLeftCell);
		}	
		
		private function splitCell():void
		{
			SplitCellDialog.open(Cell(selectedCells.getItemAt(0)),doSplitCell);
		}
		
		private function doSplitCell(targetCell:Cell,rowNum:int,colNum:int):void
		{
			var row:Row;
			var cell:Cell;
			var targetRow:Row = Row(targetCell.parent); 
			var targetRowPosition:int =getChildIndex(targetRow);
			var rowHeight:int;
			
			var targetCellPosition:int = targetRow.getChildIndex(targetCell);
			var targetCellColSpan:int = targetCell.gridColSpan;	
			
			var i:int;
			var j:int;
			
			var newRow:Row;
			
			var newCell:Cell;
			var colSpan:int;
			var cellCount:int;
			var rowCount:int;
			var rowSpan:int;
			
			//calculate the spanned rows of the target cell
			var spannedRows:Array = new Array();
			for each(row in Table(targetCell.parent.parent).getChildren())
			{
				for each(cell in row.getChildren())
				{
					if(row.gridRowIndex + cell.gridRowSpan - 1 < targetCell.gridRowIndex)
					{
						continue;
					}
					if(row.gridRowIndex > targetCell.gridRowIndex + targetCell.gridRowSpan - 1)
					{
						continue;
					}
					
					if(row.gridRowIndex < targetCell.gridRowIndex && row.gridRowIndex + cell.gridRowSpan >= targetCell.gridRowIndex + targetCell.gridRowSpan)
					{
						continue;
					}
					if(spannedRows.indexOf(row) == -1)
					{
						spannedRows.push(row);
					}
				}
			}
			
			if(spannedRows.length == 1)			
			{
				var totalRowHeight:int = rowNum * CellConst.MIN_HEIGHT;
				
				if(targetCell.height > totalRowHeight)
				{
					totalRowHeight = targetCell.height;
				} 
				var totalRowSpan:int = Math.floor(totalRowHeight / CellConst.BASIC_HEIGHT);
				
				//1. set rowSpan and height of the other cells 
				var cells:Array = this.cells;
				
				for( i = 0 ; i < cells.length; i ++)
				{
					cell = Cell(cells[i]);

					if(cell.gridRowIndex + cell.gridRowSpan -1 < targetCell.gridRowIndex)
					{
						continue;
					}
					if(cell.gridRowIndex > targetCell.gridRowIndex + targetCell.gridRowSpan - 1)
					{
						continue;
					}
					if(cell == targetCell)
					{
						continue;
					}
					cell.gridRowSpan = totalRowSpan;
					cell.height = totalRowHeight;
				}
				
				//2. add rows
				rowHeight = Math.floor(totalRowHeight / rowNum);
				
				for(i = targetRowPosition + 1; i <= targetRowPosition + rowNum - 1; i++)
				{
					newRow = new Row();
					addChildAt(newRow,i);
					newRow.height = rowHeight;
				}	
				
				targetRow.height = rowHeight;
				
				//3. add cells
				rowCount = totalRowSpan % rowNum; 
				
				for(i = targetRowPosition ; i <= targetRowPosition + rowNum - 1; i++)
				{
					row = Row(getChildAt(i));		
					
					rowSpan = Math.floor(totalRowSpan / rowNum);
					if(rowCount!=0)
					{
						rowSpan++;
						rowCount--;
					}
					
					cellCount = targetCellColSpan % colNum;
					for(j = targetCellPosition ; j <= targetCellPosition + colNum - 1;j++)
					{	
						newCell = new Cell();
						colSpan = Math.floor(targetCellColSpan/colNum);
						if(cellCount != 0 )
						{
							colSpan ++;
							cellCount -- ;							
						}
						
						if(row == targetRow)
						{
							if(j == targetCellPosition)
							{
								targetCell.gridColSpan = colSpan;
								targetCell.width = colSpan * CellConst.BASIC_WIDTH;
								targetCell.gridRowSpan = rowSpan;
								continue;
							}
							
							row.addChildAt(newCell,j);
						}
						else
						{
							row.addChild(newCell);
						}
						
						newCell.gridColSpan = colSpan;
						newCell.width = colSpan * CellConst.BASIC_WIDTH;		
						
						newCell.gridRowSpan = rowSpan;	
					}
				}
			}
			else if(spannedRows.length > 1)
			{
				//add cells and set cell width, colSpan, rowSpan.		
				var step:int = spannedRows.length / rowNum;
				for(i = targetRowPosition ; i <= targetRowPosition + spannedRows.length - 1; i += step)
				{
					row = Row(getChildAt(i)); 
					
					rowSpan = 0;
					
					for(j = i; j < i + step;j++)
					{
						var minRowSpan:int = int.MAX_VALUE;
						var tmpRow:Row = Row(getChildAt(j));
						for each(cell in tmpRow.getChildren())
						{
							minRowSpan = Math.min(minRowSpan,cell.gridRowSpan);
						}
						rowSpan += minRowSpan;
					}
					
					cellCount = targetCellColSpan % colNum;
					
					targetCellPosition = -1;
					
					var children:Array = row.getChildren();
					
					for( j = 0 ; j < children.length; j++)
					{
						cell = Cell(children[j]);
						if(cell.gridColIndex + cell.gridColSpan == targetCell.gridColIndex)
						{
							targetCellPosition = cell.parent.getChildIndex(cell);
						}
					}
					
					targetCellPosition++;
					
					for(j = targetCellPosition ; j <= targetCellPosition + colNum - 1;j++)
					{
						newCell = new Cell();
						colSpan = Math.floor(targetCellColSpan/colNum);
						if(cellCount != 0 )
						{
							colSpan ++;
							cellCount -- ;							
						}
						
						if(row == targetRow)
						{
							if(j == targetCellPosition)
							{
								targetCell.gridColSpan = colSpan;
								targetCell.width = colSpan * CellConst.BASIC_WIDTH;
								targetCell.gridRowSpan = rowSpan;
								continue;
							}
							
							row.addChildAt(newCell,j);
						}
						else
						{
							row.addChildAt(newCell,j);
						}
						
						newCell.gridColSpan = colSpan;
						newCell.width = colSpan * CellConst.BASIC_WIDTH;		
						
						newCell.gridRowSpan = rowSpan;
					}
					
				}
			}
		}		
		
		public function getChildrenFrom(rowPosition:int,cellPosition:int):Array
		{
			if(rowPosition < 0 && rowPosition > numChildren - 1)
			{
				throw new Error("there is no row at the position " + rowPosition);
			}
			var row:Row = Row(getChildAt(rowPosition));
			
			if(cellPosition < 0 && cellPosition > row.numChildren - 1)
			{
				throw new Error("there is no cell at the position " + cellPosition + "of the specified row");
			}

			var cell:Cell = Cell(row.getChildAt(cellPosition));
			
			return cell.getChildren();
		}
		
		public function removeChildrenFrom(rowPosition:int,cellPosition:int):void
		{			
			if(rowPosition < 0 && rowPosition > numChildren - 1)
			{
				throw new Error("there is no row at the position " + rowPosition);
			}
			var row:Row = Row(getChildAt(rowPosition));
			
			if(cellPosition < 0 && cellPosition > row.numChildren - 1)
			{
				throw new Error("there is no cell at the position " + cellPosition + "of the specified row");
			}

			var cell:Cell = Cell(row.getChildAt(cellPosition));
			cell.removeAllChildren();
		}
		
		public function insertChildAt(child:UIComponent, rowPosition:int,cellPosition:int):void
		{
			if(rowPosition < 0 && rowPosition > numChildren - 1)
			{
				throw new Error("there is no row at the position " + rowPosition);
			}
			var row:Row = Row(getChildAt(rowPosition));
			
			if(cellPosition < 0 && cellPosition > row.numChildren - 1)
			{
				throw new Error("there is no cell at the position " + cellPosition + "of the specified row");
			}

			var cell:Cell = Cell(row.getChildAt(cellPosition));
			cell.addChild(child);
		}			
	}
}