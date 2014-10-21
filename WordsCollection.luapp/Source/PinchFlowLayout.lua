-- PichFlowLayout: a customized UICollectionViewFlowLayout for the collection view 

local CaTransform3D = require "QuartzCore.CATransform3D"

-----------------------------------------------------------------------
-- PinchFlowLayout class creation (subclass of UICollectionViewFlowLayout)

local UICollectionViewFlowLayout = objc.UICollectionViewFlowLayout

local PinchFlowLayout = class.createClass ("PichFlowLayout", UICollectionViewFlowLayout)

-----------------------------------------------------------------------
-- Layout attributes generation

function PinchFlowLayout:layoutAttributesForElementsInRect (rect)
    -- call super
    local allAttributesInRect = self[UICollectionViewFlowLayout]:layoutAttributesForElementsInRect (rect)
    
    -- If a pinch gesture is active, handle it
    if self.pinchedCellPath ~= nil then 
        for cellAttributes in allAttributesInRect do
            if cellAttributes.indexPath:isEqual (self.pinchedCellPath) then
                self:applyPinchToLayoutAttributes (cellAttributes);
            end
        end
    end
    
    return allAttributesInRect;
end

function PinchFlowLayout:layoutAttributesForItemAtIndexPath (indexPath)
    -- call super
   local cellAttributes = self[UICollectionViewFlowLayout]:layoutAttributesForItemAtIndexPath (indexPath)
   
    -- If a pinch gesture is active, handle it
    if self.pinchedCellPath ~= nil and cellAttributes.indexPath:isEqual (self.pinchedCellPath) then 
        self:applyPinchToLayoutAttributes (cellAttributes);
    end
   
   return cellAttributes;
end

function PinchFlowLayout:applyPinchToLayoutAttributes (layoutAttributes)
    
    if self.pinchedCellCenter then
        layoutAttributes.center = self.pinchedCellCenter
    end
    
    layoutAttributes.zIndex = 1
    
    if self._pinchedCellScale then
        layoutAttributes.size = { width = layoutAttributes.size.width * self._pinchedCellScale,
                                  height = layoutAttributes.size.height * self._pinchedCellScale}
    end
    
    local transform3D = CaTransform3D.Identity
    if self.rotationAngle ~= nil then
        transform3D = CaTransform3D.Rotate (transform3D, self.rotationAngle, 0, 0, 1)
    end
    layoutAttributes.transform3D = transform3D
end

-----------------------------------------------------------------------
-- Declare getters and setters for the pinch gesture parameters

function PinchFlowLayout:setPinchCellPath (path)
    
    self._pinchedCellPath = path
    
    if path ~= nil then
        local invalidateContext = objc.UICollectionViewFlowLayoutInvalidationContext:new()
        invalidateContext.invalidateFlowLayoutDelegateMetrics = false
        invalidateContext:invalidateItemsAtIndexPaths {path}
        self.pinchInvalidationContext = invalidateContext
        self:invalidateLayoutWithContext (self.pinchInvalidationContext)
    else
        self:invalidateLayout()
    end
end

PinchFlowLayout:declareSetters { pinchedCellPath = "setPinchCellPath",                                                       
                                 pinchedCellScale = function (self, scale)
                                                        self._pinchedCellScale = scale
                                                        self:invalidateLayoutWithContext (self.pinchInvalidationContext)
                                                    end,
                                 pinchedCellCenter = function (self, origin)
                                                         self._pinchedCellCenter = origin
                                                         self:invalidateLayoutWithContext (self.pinchInvalidationContext)
                                                     end,
                                 rotationAngle = function (self, angle)
                                                     self._rotationAngle = angle
                                                     self:invalidateLayoutWithContext (self.pinchInvalidationContext)
                                                 end,
                               }

PinchFlowLayout:declareGetters { pinchedCellPath = function (self) return self._pinchedCellPath end,
                                 pinchedCellScale = function (self) return self._pinchedCellScale end,
                                 pinchedCellCenter = function (self) return self._pinchedCellCenter end,
                                 rotationAngle = function (self) return self._rotationAngle end, 
                               }

return PinchFlowLayout