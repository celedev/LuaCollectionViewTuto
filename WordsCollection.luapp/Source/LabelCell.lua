-- LabelCell: a specific UICollectionViewCell with a Text label in it

local UiView = require "UIKit.UIView"
local NsText = require "UIKit.NSText"
local CaTransform3D = require "QuartzCore.CATransform3D"

-----------------------------------------------------------------------
-- LabelCell class creation (subclass of UICollectionViewCell)

local UICollectionViewCell = objc.UICollectionViewCell

local LabelCell = class.createClass ("LabelCell", UICollectionViewCell)

-----------------------------------------------------------------------
-- LabelCell initializer

function LabelCell:initWithFrame (frame)
    
    -- Call super
    self = self[UICollectionViewCell]:initWithFrame (frame)
    
    if self ~= nil then
        -- configure the cell's content and appearance
        self:setAppearance()
    end    
    
    return self    
end  

-----------------------------------------------------------------------
-- LabelCell configuration

-- Define local references to Objective C classes
local UILabel = objc.UILabel
local UIFont = objc.UIFont
local UIColor = objc.UIColor

function LabelCell:setAppearance (cellIndex, cellCount)
    
    -- set default values to params if nil (when called from initWithFrame)
    cellIndex, cellCount = cellIndex or 0, cellCount or 1
    
    self.cellIndex = cellIndex
    self.cellCount = cellCount
    
    local contentView = self.contentView
    local contentViewSize = contentView.size
    
    local label = self.label
    
    if label == nil then
        -- create the label and add it to the content view
        label = UILabel:newWithFrame(contentView.bounds)
        label.autoresizingMask = UiView.Autoresizing.FlexibleHeight + UiView.Autoresizing.FlexibleWidth
        label.textAlignment = NsText.Alignment.Center
        contentView:addSubview (label)
        self.label = label
    end
    
    if self.layoutAttributesSize then
        label.font = LabelCell:labelFontForSize(self.layoutAttributesSize)
    else
        label.font = UIFont:boldSystemFontOfSize (28.0)
    end
    
    label.backgroundColor = UIColor.clearColor
    label.shadowColor = UIColor.darkGrayColor
    label.textColor = UIColor.whiteColor
    
    -- Content view
    contentView.clipsToBounds = true
    contentView.layer.borderWidth = 10
    
    -- Cell colors
    local cellHue = (cellIndex / cellCount + 0.4) % 1.0
    contentView.backgroundColor = UIColor:colorWithHue_saturation_brightness_alpha (cellHue, 0.2, 0.8, 1)
    contentView.layer.borderColor = UIColor:colorWithHue_saturation_brightness_alpha (cellHue, 0.9, 0.8, 1).CGColor
end

-----------------------------------------------------------------------
-- LabelCell layout-based customization 

function LabelCell:applyLayoutAttributes (layoutAttributes)
    -- call super
    self[UICollectionViewCell]:applyLayoutAttributes(layoutAttributes)
    
    local label = self.label
    self.layoutAttributesSize = layoutAttributes.size
    
    label.font = LabelCell:labelFontForSize(self.layoutAttributesSize)
    
    local transform3D = layoutAttributes.transform3D
    if self.cellIndex and (transform3D ~= nil) and not CaTransform3D.IsIdentity(transform3D) then
        local cellHue = (self.cellIndex / self.cellCount + 0.9) % 1.0
        label.textColor = UIColor:colorWithHue_saturation_brightness_alpha (cellHue, 0.9, 0.8, 1)
    else
        label.textColor = UIColor.whiteColor
    end
end

-----------------------------------------------------------------------
-- Utility class method

function LabelCell.classMethod:labelFontForSize (proposedSize)
    return UIFont:boldSystemFontOfSize (--[[ math.min(proposedSize.width,]] proposedSize.height  * 0.4)
end

-----------------------------------------------------------------------
-- return LabelCell class

return LabelCell;