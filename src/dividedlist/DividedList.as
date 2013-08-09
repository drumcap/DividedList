package dividedlist {

import flash.display.DisplayObject;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;

import mx.collections.IList;
import mx.core.IDataRenderer;
import mx.core.IFactory;
import mx.core.IVisualElement;
import mx.core.mx_internal;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;

import spark.components.List;

import spark.components.supportClasses.GroupBase;
import spark.layouts.VerticalLayout;

use namespace mx_internal;

/** logic to make the header stick to the top and move nicely, if another divider pushed it */
public class DividedList extends List
{

    [SkinPart (required=true)]
    public var header : DisplayObject;
    protected var dividerIndexes : Array = [];
    protected var lastScrollPosition : Number = 0;
    public static const SCROLL_POSITION_CHANGED : String = "scrollPositionChanged";

    override public function set dataProvider(dataP : IList) : void
    {
        super.dataProvider = dataP;
        dividerIndexes = [];
        for (var i : int = 0; i < dataP.length; i++)
        {
            if ( dataP.getItemAt(i).isDivider )
            {
                dividerIndexes.push(i);
            }
        }
        headerVisible = (dividerIndexes.length > 0);
        addEventListener(FlexEvent.UPDATE_COMPLETE, handleUpdateComplete);
    }

    override public function set itemRenderer(factory : IFactory) : void
    {
        super.itemRenderer = factory;
        dispatchEvent(new Event("rendererChanged"));
        if (skin)
        {
            header = skin["header"];
            updateHeader();
        }
    }

    public function set headerVisible(value : Boolean) : void
    {
        if (!header)
        {
            return;
        }
        header.visible = value;
        scroller.viewport.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, handleUpdateScrollPosition);
        if (value == true)
        {
            updateHeader();
            scroller.viewport.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, handleUpdateScrollPosition);
            skin.invalidateDisplayList();
        }
    }

    public function scrollIndexToTop(index : Number) : void
    {
        setScrollPosition( index, -1 );
    }

    public function setScrollPosition(index : Number, fractionInView : Number) : void
    {
        removeEventListener(FlexEvent.UPDATE_COMPLETE, handleUpdateComplete);
        var vLayout : VerticalLayout = dataGroup.layout as VerticalLayout;
        for (var i : int = 0; i < 10; i++)
        {
            var deltaToElement : Point = vLayout.getScrollPositionDeltaToElement(index);
            if (!deltaToElement || deltaToElement.x == 0 && deltaToElement.y == 0)
            {
                break;
            }
            vLayout.horizontalScrollPosition = vLayout.horizontalScrollPosition + deltaToElement.x;
            vLayout.verticalScrollPosition = vLayout.verticalScrollPosition + deltaToElement.y;
        }
        validateNow();
        // getElementBounds does not work correctly with verticalLayout, thus big jumps will be inaccurate, if
        // the element sized are different
        var scrollPosRect : Rectangle = dataGroup.layout.getElementBounds(index);
        if (dataGroup.layout.getElementBounds(index) == null)
        {
            return;
        }
        if (fractionInView == -1)
        {
            scroller.viewport.verticalScrollPosition = Math.max(0, scrollPosRect.y - header.height);
        }
        else
        {
            const indicesInView : Vector.<int> = dataGroup.getItemIndicesInView();
            const firstItemInView : Object = dataGroup.dataProvider.getItemAt(index);
            for (var j : int = 0; j < indicesInView.length; j++)
            {
                const currRend : IDataRenderer = dataGroup.getElementAt(indicesInView[j]) as IDataRenderer;
                if (currRend && currRend.data == firstItemInView)
                {
                    scroller.viewport.verticalScrollPosition = scrollPosRect.y +
                                                               (1 - fractionInView) *
                                                               (currRend as IVisualElement).getLayoutBoundsHeight();
                    break;
                }
            }
        }
        validateNow();
        updateHeader(0, true);
    }

    override mx_internal function setSelectedIndex(value : int, dispatchChangeEvent : Boolean = false, changeCaret : Boolean = true) : void
    {
        // copypaste from the  parent function with the return statement removed
        if (value == selectedIndex)
        {
            if (changeCaret)
            {
                setCurrentCaretIndex(selectedIndex);
            }
        }
        if (dispatchChangeEvent)
        {
            dispatchChangeAfterSelection = (dispatchChangeAfterSelection || dispatchChangeEvent);
        }
        changeCaretOnSelection = changeCaret;
        _proposedSelectedIndex = value;
        invalidateProperties();
    }

    override protected function partAdded(partName:String, instance:Object) : void
    {
        super.partAdded(partName, instance);
        if (instance == scroller)
        {
            scroller.viewport.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, handleUpdateScrollPosition);
        }
    }

    override protected function partRemoved(partName : String, instance : Object) : void
    {
        super.partRemoved(partName, instance);
        if (instance == scroller)
        {
            scroller.viewport.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, handleUpdateScrollPosition);
        }
    }

    protected function handleUpdateScrollPosition(event : PropertyChangeEvent) : void
    {
        if (event.property == "verticalScrollPosition")
        {
            updateHeader(Number(event.newValue) - Number(event.oldValue));
        }
    }

    override protected function mouseUpHandler(event : Event) : void
    {
        const dispO : DisplayObject = (dataGroup ? (dataGroup.getElementAt(mouseDownIndex)) : (null)) as DisplayObject;
        var po : Point = new Point(mouseX, mouseY);
        po = localToGlobal(po);
        if (dispO && pendingSelectionOnMouseUp && !dispO.hitTestPoint(po.x, po.y))
        {
            setSelectedIndex(-1, true);
            pendingSelectionOnMouseUp = false;
            itemSelected(mouseDownIndex, false);
        }
        super.mouseUpHandler(event);
        if (lastScrollPosition != scroller.viewport.verticalScrollPosition)
        {
            lastScrollPosition = scroller.viewport.verticalScrollPosition;
            dispatchEvent(new Event(SCROLL_POSITION_CHANGED));
        }
    }

    protected function updateHeader(scrollDelta : Number = 0, isPosSet : Boolean = false) : void
    {
        if (header == null)
        {
            return;
        }
        const vScrollPosition : Number = scroller.viewport.verticalScrollPosition;
        if (!dataProvider || dataProvider.length == 0 || dividerIndexes.length == 0)
        {
            header.visible = false;
            return;
        }
        var prevDividerIndex : int = 0;
        const scrollerGroup : GroupBase = scroller.viewport as GroupBase;
        const vLayout : VerticalLayout = layout as VerticalLayout;
        var prevDivider : IVisualElement = null;
        for (var i : int = dividerIndexes.length; i > -1; i--)
        {
            if (vLayout.firstIndexInView >= dividerIndexes[i])
            {
                prevDividerIndex = i;
                prevDivider = scrollerGroup.getElementAt(dividerIndexes[i]);
                if (prevDivider)
                {
                    prevDivider.visible = (vScrollPosition < 0);
                }
                break;
            }
        }

        if (vScrollPosition < 0)
        {
            header.visible = false;
            return;
        }

        var headery : Number = 0;
        var nextHeadery : Number = 0;
        if ((prevDividerIndex + 1) < dividerIndexes.length)
        {
            prevDivider = scrollerGroup.getElementAt(dividerIndexes[(prevDividerIndex + 1)]);
            if (prevDivider)
            {
                nextHeadery = prevDivider.y - vScrollPosition;
                if (((scrollDelta > 0 || isPosSet) && nextHeadery < header.height) ||
                    ((scrollDelta < 0 || isPosSet) && nextHeadery < header.height))
                {
                    headery = nextHeadery - header.height;
                }
                prevDivider.visible = true;
            }
        }

        if (header.y != headery)
        {
            header.y = headery;
        }

        header.visible = true;
        const prevDividerData : Object = dataProvider.getItemAt(dividerIndexes[prevDividerIndex]);
        if (header is IDataRenderer && IDataRenderer(header).data != prevDividerData)
        {
            IDataRenderer(header).data = prevDividerData;
        }
    }

    protected function handleUpdateComplete(event : Event) : void
    {
        updateHeader();
        removeEventListener(FlexEvent.UPDATE_COMPLETE, handleUpdateComplete);
    }

}
}
