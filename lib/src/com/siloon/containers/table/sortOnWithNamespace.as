package com.siloon.containers.table
{
	public function sortOnWithNamespace(array:Array,fieldName:Object, nameSpace:Namespace,options:Object=null):Array
	{
		var value1:Object;
		var value2:Object;
		
		var casesensitive:Boolean = (Number(options) & Array.CASEINSENSITIVE) != 0;
		var desending:Boolean = (Number(options) & Array.DESCENDING) != 0;
		var numeric:Boolean = (Number(options) & Array.NUMERIC) != 0;
		var returnindexedarray:Boolean = (Number(options) & Array.RETURNINDEXEDARRAY) != 0;
		var uniquesort:Boolean = (Number(options) & Array.UNIQUESORT) != 0;
		
		var sort:Function = function(obj1:Object,obj2:Object):Number
		{								
			if(numeric)
			{
				value1 = Number(obj1.nameSpace::[fieldName]);
				value2 = Number(obj2.nameSpace::[fieldName]);
				
				if(value1 > value2)
				{
					if(desending)
					{
						return -1;
					}
					else
					{
						return 1;
					}
				}	
				
				else if(value1 < value2)
				{
					if(desending)
					{
						return 1;
					}
					else
					{
						return -1;
					}
				}
				else
				{
					return 0;
				}	
			}
			return 0;						
		}
		return array.sort(sort);
	};
}