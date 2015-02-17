-- CollectionController: the UICollectionViewController for this collection view

local CollectionViewLayout = require "PinchFlowLayout"
local ViewCellClass        = require "LabelCell"

local UiGestureRecognizer = require "UIKit.UIGestureRecognizer"
local NsString = require "Foundation.NSString"
local NsStringAttributes = require "UIKit.NSAttributedString"

-----------------------------------------------------------------------
-- Create the CollectionController class (subclass of UICollectionViewController)

local UICollectionViewController = objc.UICollectionViewController

local CollectionController = class.createClass ("CollectionController", UICollectionViewController)

-----------------------------------------------------------------------
-- Base methods

function CollectionController:init ()
    -- call super
    return self[UICollectionViewController]:initWithCollectionViewLayout (CollectionViewLayout:new())
end  

function CollectionController:viewDidLoad ()
    
    -- register the cell class
    self.collectionView:registerClass_forCellWithReuseIdentifier (ViewCellClass, "LABEL_CELL")
    
    -- subscribe to the module load messages
    self:addMessageHandler ("system.did_load_module", "refresh")
    
    -- configure the collection view
    self:configureCollectionView ()
end

function CollectionController:configureCollectionView ()
    
    local collectionView = self.collectionView
    collectionView.collectionViewLayout.itemSize = { width = 100, height = 54 }

    if self.pinchRecognizer == nil then
        -- Create a pinch gesture recognizer
        local pinchRecognizer = objc.UIPinchGestureRecognizer:newWithTarget_action (self, "handlePinchGesture")
        pinchRecognizer.delegate = self
        collectionView:addGestureRecognizer (pinchRecognizer)
        self.pinchRecognizer = pinchRecognizer
    end
    
    if self.rotationRecognizer == nil then
        -- Create a rotation gesture recognizer
        local rotationRecognizer = objc.UIRotationGestureRecognizer:newWithTarget_action (self, "handleRotationGesture")
        rotationRecognizer.delegate = self
        collectionView:addGestureRecognizer (rotationRecognizer)
        self.rotationRecognizer = rotationRecognizer
    end
    
    if self.textWords == nil then
        getResource ("h2g2", "txt", self, "collectionText")
    end
end

-----------------------------------------------------------------------
-- Collection view data source methods

local baseCellCount = 70

function CollectionController:collectionView_numberOfItemsInSection (view, section)
    return self.textWords and #self.textWords or baseCellCount;
end  

function CollectionController:collectionView_cellForItemAtIndexPath (collectionView, indexPath)
    
    -- get a cell from the collection view
    local cell = collectionView:dequeueReusableCellWithReuseIdentifier_forIndexPath ("LABEL_CELL", indexPath);
    
    local cellIndex = indexPath.item
    
    -- configure the cell appearance
    cell:setAppearance (cellIndex, baseCellCount)
    
    -- set the cell text (Lua strings will be automatically converted to Objective-C NSString)
    cell.label.text = self.textWords and self.textWords[cellIndex +1] or ("Yo" .. tostring(cellIndex + 1))
    
    -- and return the cell
    return cell
end

-----------------------------------------------------------------------
-- Collection view flow layout delegate methods

function CollectionController:collectionView_layout_sizeForItemAtIndexPath(collectionView, layout, indexPath)
    local cellIndex = indexPath.item + 1
    local cellFont = ViewCellClass:labelFontForSize(layout.itemSize)
    local cellSize
    if self.textWords and (cellIndex <= #self.textWords) then
        local cellLabelSize = self.textWords[cellIndex]:sizeWithAttributes 
                              { [NsStringAttributes.NSFontAttributeName] = cellFont } -- iOS 8
        -- local cellLabelSize = self.textWords[cellIndex +1]:sizeWithFont (cellFont) -- iOS 6-7
        cellSize = struct.CGSize(cellLabelSize.width + 30, layout.itemSize.height)
    else
        cellSize = layout.itemSize
    end
    
    return cellSize
end

CollectionController:publishObjcProtocols ("UICollectionViewDelegateFlowLayout")

-----------------------------------------------------------------------
-- Resource setters

function CollectionController:setCollectionText(text)
    local fullRange = struct.NSRange(0, text.length)
    local words = {}
    local wordsCount = 0
    text:enumerateSubstringsInRange_options_usingBlock (fullRange, NsString.EnumerationOptions.ByWords, 
                                                        function(word) 
                                                            wordsCount = wordsCount + 1
                                                            words[wordsCount] = word
                                                        end)
    
    self.textWords = words
    self.collectionView:reloadData()
end

CollectionController:declareSetters { collectionText = "setCollectionText" }

-----------------------------------------------------------------------
-- Gesture recognizers action methods

local UIGestureRecognizerState = UiGestureRecognizer.State

function CollectionController:handlePinchGesture (gestureRecognizer)
    
    local layout = self.collectionView.collectionViewLayout
    
    if gestureRecognizer.state == UIGestureRecognizerState.Began then
        
        if layout.pinchedCellPath == nil then
            local initialPinchPoint = gestureRecognizer:locationInView (self.collectionView)
            layout.pinchedCellPath = self.collectionView:indexPathForItemAtPoint (initialPinchPoint)
        end
        
    elseif gestureRecognizer.state == UIGestureRecognizerState.Changed then
        
        layout.pinchedCellScale  = gestureRecognizer.scale
        
        if gestureRecognizer.numberOfTouches > 1 then
            layout.pinchedCellCenter = gestureRecognizer:locationInView (self.collectionView)
        end
        
    else
        -- We simply pass Lua functions for Objective C blocks parameters
        self.collectionView:performBatchUpdates_completion (function ()
                                                                layout.pinchedCellScale = 1                                                                
                                                                layout.pinchedCellCenter = nil
                                                            end,
                                                            function (finished)
                                                                layout.pinchedCellPath = nil
                                                             end)
    end
end

-- Publish method 'handlePinchGesture' to make it callable from Objective C
CollectionController:publishActionMethod ("handlePinchGesture")

function CollectionController:handleRotationGesture (gestureRecognizer)
    
    local layout = self.collectionView.collectionViewLayout
    
    if gestureRecognizer.state == UIGestureRecognizerState.Began then
        
        if layout.pinchedCellPath == nil then
            local initialPinchPoint = gestureRecognizer:locationInView (self.collectionView)
            layout.pinchedCellPath = self.collectionView:indexPathForItemAtPoint (initialPinchPoint)
        end
        
    elseif gestureRecognizer.state == UIGestureRecognizerState.Changed then
        
        layout.rotationAngle = gestureRecognizer.rotation
        
    else
        self.collectionView:performBatchUpdates_completion (function () 
                                                                layout.rotationAngle = nil 
                                                            end, 
                                                            function (finished)
                                                                layout.pinchedCellPath = nil
                                                            end)
    end
end

CollectionController:publishActionMethod ("handleRotationGesture")

-- Protocol UIGestureRecognizerDelegate

function CollectionController:gestureRecognizer_shouldRecognizeSimultaneouslyWithGestureRecognizer(recognizer1, recognizer2)
    return ((recognizer1 == self.pinchRecognizer) and (recognizer2 == self.rotationRecognizer)) or
            ((recognizer2 == self.pinchRecognizer) and (recognizer1 == self.rotationRecognizer))
end

CollectionController:publishObjcProtocols {"UIGestureRecognizerDelegate"}

-----------------------------------------------------------------------
-- CollectionView refresh method (called when a code module is updated)

function CollectionController:refresh ()
   
   local collectionView = self.collectionView   
   
    if collectionView ~= nil then
        self:configureCollectionView ()
        collectionView:reloadData()  
        collectionView.collectionViewLayout:invalidateLayout()
   end
   
end  

-----------------------------------------------------------------------
-- return the CollectionController class

return CollectionController;
