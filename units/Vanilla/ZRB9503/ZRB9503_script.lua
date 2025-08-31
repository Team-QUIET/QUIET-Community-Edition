--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local CSeaFactoryUnit = import('/lua/cybranunits.lua').CSeaFactoryUnit

local WaitFor = WaitFor

ZRB9503 = ClassUnit(CSeaFactoryUnit) {
    
    StartArmsMoving = function(self)
        CSeaFactoryUnit.StartArmsMoving(self)
        if not self.ArmSlider1 then
            self.ArmSlider1 = CreateSlider(self, 'Right_Arm02')
            self.Trash:Add(self.ArmSlider1)
        end
        if not self.ArmSlider2 then
            self.ArmSlider2 = CreateSlider(self, 'Right_Arm03')
            self.Trash:Add(self.ArmSlider2)
        end
    end,

    MovingArmsThread = function(self)
        CSeaFactoryUnit.MovingArmsThread(self)
		local WaitFor = WaitFor
        while true do
            if not self.ArmSlider1 then return end
            if not self.ArmSlider2 then return end
            self.ArmSlider1:SetGoal(20, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(-20, 0, 0)
            self.ArmSlider2:SetSpeed(40)
            WaitFor(self.ArmSlider2)
            self.ArmSlider1:SetGoal(0, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(0, 0, 0)
            self.ArmSlider2:SetSpeed(40)
            WaitFor(self.ArmSlider2)
        end
    end,
    
    StopArmsMoving = function(self)
        CSeaFactoryUnit.StopArmsMoving(self)
        if self.ArmSlider1 then
            self.ArmSlider1:SetGoal(0, 0, 0)
            self.ArmSlider1:SetSpeed(40)
        end
        if self.ArmSlider2 then
            self.ArmSlider2:SetGoal(0, 0, 0)
            self.ArmSlider2:SetSpeed(40)
        end
    end,
}

TypeClass = ZRB9503
