AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "AI Turret"
ENT.Author = "Mikey_0161"
ENT.Spawnable = true
ENT.Category = "Weapons"

function ENT:Initialize()
    self:SetModel("models/props_combine/bunker_gun01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    
    -- Disable physics rotation
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
    
    -- Turret properties
    self.Target = nil
    self.NextShot = CurTime()
    self.FireRate = 0.1
    self.Range = 2000
    self.SearchRange = 3000
	self.RotationSpeed = 200.0
	self.YawSpeed = 200.0
    self.PitchSpeed = 200.0
    self.TurretHealth = 100
    self.MaxHealth = 100
end

function ENT:OnTakeDamage(dmginfo)
    self.TurretHealth = self.TurretHealth - dmginfo:GetDamage()
    
    if self.TurretHealth <= 0 then
        self:Remove()
    end
end

function ENT:FindTarget()
    local nearestDist = self.SearchRange
    local target = nil
    
    -- Search for NPCs and players
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent ~= self then
            local isValid = false
            
            -- Only target NPCs (not players including owner)
            if ent:IsNPC() then
                isValid = true
            end
            
            if isValid then
                local dist = self:GetPos():Distance(ent:GetPos())
                
                if dist < nearestDist then
                    -- Check line of sight
                    local tr = util.TraceLine({
                        start = self:GetPos(),
                        endpos = ent:WorldSpaceCenter(),
                        filter = self
                    })
                    
                    if tr.Entity == ent or tr.Fraction > 0.95 then
                        nearestDist = dist
                        target = ent
                    end
                end
            end
        end
    end
    
    return target
end

function ENT:AimAtTarget(target)
    local myPos = self:GetPos()
    local targetPos = target:WorldSpaceCenter()
    local dir = (targetPos - myPos):GetNormalized()
    
    -- Convert direction to angles
    local angles = dir:Angle()
    
    -- Smoothly rotate towards target
    local currentAngles = self:GetAngles()
    
    local yaw = Lerp(FrameTime() * 4.0, currentAngles.y, angles.y)
    local pitch = Lerp(FrameTime() * 4.0, currentAngles.p, angles.p)
    
    self:SetAngles(Angle(pitch, yaw, currentAngles.r))
end

function ENT:Shoot()
    if CurTime() < self.NextShot then return end
    
    local forward = self:GetForward()
    local pos = self:GetPos() + forward * 50
    
    -- Create a proper bullet trace
    local tr = util.TraceLine({
        start = pos,
        endpos = pos + forward * 5000,
        filter = self,
        mask = MASK_SHOT
    })
    
    -- Deal damage to hit entity
    if IsValid(tr.Entity) then
        if (tr.Entity:IsNPC() or tr.Entity:IsPlayer()) and tr.Entity.TakeDamage then
            tr.Entity:TakeDamage(25)
        end
    end
    
    -- Muzzle flash
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetAngles(self:GetAngles())
    util.Effect("muzzleflash", effectdata)
    
    -- Sound
    self:EmitSound("npc/turret_floor/shoot2.wav")
    
    self.NextShot = CurTime() + self.FireRate
end

function ENT:Think()
    if IsValid(self.Target) then
        local dist = self:GetPos():Distance(self.Target:GetPos())
        
        if dist < self.Range then
            self:AimAtTarget(self.Target)
            self:Shoot()
        else
            self.Target = nil
        end
    else
        self.Target = self:FindTarget()
    end
    
    self:NextThink(CurTime() + 0.01)
    return true
end

function ENT:Use(activator, caller)
    self.Active = !self.Active
end

function ENT:Draw()
    self:DrawModel()
end