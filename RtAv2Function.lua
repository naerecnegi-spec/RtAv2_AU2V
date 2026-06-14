--[[
    :RtAv2RppData:
        tempo               BPM
        beatchild           拍子(分子)
        beatmum             拍子(分母)
        name                ファイル名
        version             バージョン
        maxitem             最大アイテム数

        track[number]       トラックデータ
            name                トラックの名前

            item[number]        アイテムデータ
                pos                 開始位置
                length              長さ
                pich                音程



    :info:
        i       描画番号(1つ目に描画するものは1てきな)
        track   対象トラック

        effect["name"]  どんなエフェクトがかけられたか
            :"name"     エフェクトの名前
                
]]















---timeの時に何番目のアイテムか
---@param item table itemテーブル
---@param time number 時間
---@return number 何番目か
local function timeItemNum(item,time)
    local c=0
    for i=1,#item do
        if(time<item[i].pos)then
            break;
        end
        c=c+1
    end
    return math.min(c,#item),math.min(c,#item)
end

---timeの時のアイテムが何周期目の何番か(音程)
---@param item table itemテーブル
---@param time number 時間
---@return number 何番目か
local function timeItemNumPich(item,time)
    local c=0
    local c2=0
    local p=-1000
    for i=1,#item do
        if(time<item[i].pos)then
            break;
        end
        if(p~=item[i].pich)then
            c2=c2+1
            p=item[i].pich
        end
        c=c+1
    end
    return math.min(c,#item),c2
end

---i番目のアイテムが何周期目の何番か(音程)
---@param item table itemテーブル
---@param i number 時間
---@return number 何番目か
local function itemNumPich(item,i)
    local c2=0
    local p=-1000
    for j=1,i do
        if(p~=item[j].pich)then
            c2=c2+1
            p=item[j].pich
        end
    end
    return i,c2
end



---1文字を数値に
---@param s string 文字列
---@param i number 何文字目か
---@return number 変換された数値
local function string2number(s,i)
    
    return tonumber(s:sub(i,i)) or 0
end

---文字列から1文字だけ
---@param s string 文字列
---@param i number 何文字目か
---@return number 1文字
local function string1(s,i)
    return (s:sub(i,i)) or "0"
end


---周期文字列の長さで周期(語彙)
---@param s string 周期文字列
---@param i number 数
---@return number 
local function stringCycleNum(s,i)
    return ((i-1)%s:len())+1
end

---数と周期文字列から数値を返す(語彙)
---@param s string 周期文字列
---@param i number 数
---@return number 
local function string2numberCycle(s,i)
    return string2number(s,stringCycleNum(s,i))
    
end


---数と周期文字列から文字を返す(語彙)
---@param s string 周期文字列
---@param i number 数
---@return string
local function stringCycle(s,i)
    return string1(s,stringCycleNum(s,i))
    
end

---基準音程を加味した値を返す
---@param p string 音程
---@return number 加味した値
local function PICH(p)
    return p+ (RtAv2Data.pich or 0)
end

---基準長さを加味した値を返す
---@param p string 長さ
---@return number 加味した値
local function LENGTH(p)
    if((RtAv2Data.length or 0)==0)then
        return p
    else
        if(p>=RtAv2Data.length)then
            return (p/RtAv2Data.length)-1
        else
            return -(RtAv2Data.length/p)+1
        end
    end
end


local function ZOOM(p)
    if(p>=0)then
        return p/100+1
    else
        return 1/(-p/100+1)
    end
end

local function ALPHA(p)
    if(p>=0)then
        return -p/100+1
    else
        return (-p/100)+1
    end
end

---タイプからピッチなどで加工した値を返す
---@param type number タイプ(1~4)
---@param item table アイテムデータ
---@param count number 描画順
---@param v number 加工前の値
---@return number 加工後の値
local function typeItemValue(type,item,count,v)
    if(type=="0")then
        return 0
    elseif(type=="1")then
        return v
    elseif(type=="2")then
        return -v
    elseif(type=="3")then
        return v*PICH(item.pich)
    elseif(type=="4")then
        return -v*PICH(item.pich)
    elseif(type=="5")then
        return v*count
    elseif(type=="6")then
        return -v*count
    elseif(type=="7")then
        return v*LENGTH(item.length)
    elseif(type=="8")then
        return -v*LENGTH(item.length)
    else
        return 0
    end
end
---タイプからピッチなどで加工した値を返す(拡大率)
---@param type number タイプ(1~4)
---@param item table アイテムデータ
---@param count number 描画順
---@param v number 加工前の値
---@return number 加工後の値
local function typeItemZoomValue(type,item,count,v)
    local e=2.718281828459
    if(type=="0")then
        return 1
    elseif(type=="1")then
        return v
    elseif(type=="2")then
        return 1/v
    elseif(type=="3")then
        return v*PICH(item.pich)
    elseif(type=="4")then
        return 1/(v*PICH(item.pich))
    elseif(type=="5")then
        return v*count
    elseif(type=="6")then
        return 1/(v*count)
    elseif(type=="7")then
       -- return math.pow(e,math.log(v,e)*math.log(LENGTH(item.length),e))
       return v*LENGTH(item.length)
    elseif(type=="8")then
        return 1/(v*LENGTH(item.length))
    else
        return 1
    end
end




---その時間,ターゲットなどのときに何番目のアイテムで何周期目か
---@param target number ターゲット
---@param track table Trackデータ
---@param info table infoデータ
---@param pich integer 音程を考えるかどうか
---@param option integer オプション
---@return number,number  何番目,何周期目
local function timeItemNumTarget(target,track,info,pich,option)
    option=option or 0
    pich=pich or 0
    if(option==0)then
        if(pich==0)then

            if(target==0)then
                return timeItemNum(track[info.track].item,info.time)
            elseif(target>0)then
                local c1,c2=timeItemNum(track[target].item,info.time)
                return c1,c2,target
            elseif(target<0)then
                if(-target==info.i)then
                    return timeItemNum(track[info.track].item,info.time)
                end
            end
        else
            if(target==0)then
                return timeItemNumPich(track[info.track].item,info.time)
            elseif(target>0)then
                local c1,c2=timeItemNumPich(track[target].item,info.time)
                return c1,c2,target
            elseif(target<0)then
                if(-target==info.i)then
                    return timeItemNumPich(track[info.track].item,info.time)
                end
            end
        end
    elseif(option==1)then
        if(pich==nil or pich==0)then
            return info.i,info.i
        else
            return itemNumPich(track[target].item,info.i)
        end
    end
        return false
end



---RtAv2Dataの初期化
local function RtAv2DataInit()
    RtAv2Data={}
    RtAv2Data.f={}
    RtAv2Data.ff={}
    RtAv2Data.draw={}
    RtAv2Data.i=1
    RtAv2Data.pich=0
    RtAv2Data.length=0
end 

---描画時にかける関数を追加する
---@param f function 関数
---@param v any 設定値
local function addFunction(f,v)
    RtAv2Data=RtAv2Data or {}
    RtAv2Data.f=RtAv2Data.f or {}
    local n=#RtAv2Data.f+1
    RtAv2Data.f[n] = {}
    RtAv2Data.f[n].f=f
    RtAv2Data.f[n].v=v
end

---描画時にかける最初の関数を追加する
---@param f function 関数
---@param v any 設定値
local function addFirstFunction(f,v)
    RtAv2Data=RtAv2Data or {}
    RtAv2Data.ff=RtAv2Data.ff or {}
    local n=#RtAv2Data.ff+1
    RtAv2Data.ff[n] = {}
    RtAv2Data.ff[n].f=f
    RtAv2Data.ff[n].v=v
end

---描画時にかける描画関数を追加する
---@param f function 関数
---@param v any 設定値
local function addDrawFunction(f,v)
    RtAv2Data=RtAv2Data or {}
    RtAv2Data.draw=RtAv2Data.draw or {}
    local n=#RtAv2Data.draw+1
    RtAv2Data.draw[n] = {}
    RtAv2Data.draw[n].f=f
    RtAv2Data.draw[n].v=v
end


---描画数を設定する
---@param i number 描画数
local function setDrawNum(i)
    RtAv2Data=RtAv2Data or {}
    RtAv2Data.i=i
end

---基準音程を設定する
---@param i number 基準音程
local function setPichNum(i)
    RtAv2Data=RtAv2Data or {}
    RtAv2Data.pich=i
end


---基準長さを設定する
---@param i number 基準長さ
local function setLengthNum(i)
    RtAv2Data=RtAv2Data or {}
    RtAv2Data.length=i
end


---AからBへP!!!
---@param a number
---@param b number
---@param p number 0~1
---@return number
local function AtoB(a,b,p)
    return a + (b-a)*p
end

---typeに応じた値の加工
---@param type any 加工する種類
---@param a number
---@param b number
---@param p any
---@param e any イージング関数
---@return number 加工後の値
local function typeAtoB(type,a,b,p,e)
    
    if(type=="0")then --何もなし
        return nil
    elseif(type=="1")then --矩形波
        return b
    elseif(type=="2" or type=="3" or type=="4")then
       
        if(e==nil)then
            return AtoB(a,b,p)
        else

            return e(p,a,b-a,1)
        end
    else
        return nil
    end
end

--93氏のスクリプトを参考に
local easelist = {
    "linear",                                               -- 1
    "inSine",   "outSine",   "inOutSine",   "outInSine",    -- 2,3,4,5
    "inQuad",   "outQuad",   "inOutQuad",   "outInQuad",    -- 6,7,8,9
    "inCubic",  "outCubic",  "inOutCubic",  "outInCubic",   -- 10,11,12,13
    "inQuart",  "outQuart",  "inOutQuart",  "outInQuart",   -- 14,15,16,17
    "inQuint",  "outQuint",  "inOutQuint",  "outInQuint",   -- 18,19,20,21
    "inExpo",   "outExpo",   "inOutExpo",   "outInExpo",    -- 22,23,24,25
    "inCirc",   "outCirc",   "inOutCirc",   "outInCirc",    -- 26,27,28,29
    "inElastic","outElastic","inOutElastic","outInElastic", -- 30,31,32,33
    "inBack",   "outBack",   "inOutBack",   "outInBack",    -- 34,35,36,37
    "inBounce", "outBounce", "inOutBounce", "outInBounce"   -- 38,39,40,41
}
local _e,easing=pcall(require, "easing")
if(_e==false)then
    easing=nil
end


---イージング番号に応じたイージング関数を返す
---@param e number イージング番号
---@return function イージング関数
local function getEasing(e)
    if(easing==nil)then return nil end
    return easing[easelist[e]]
end 


--[[
pi:波形種類
hi:乗算種類
]]

---RtAv2(エフェクト)@移動などで使う関数
---@param rpp table
---@param info table
---@param data table
---@return table
local function getXYZ(rpp,info,data)
    local s2nc=stringCycle--string2numberCycle
    local tiv=typeItemValue
   
    local time=info.time
    local pos={}
    for i=1,#data.p do
        local track=info.track
        pos[i]=0
        for j=1,#data.t[i] do
            local c1,c2,t=timeItemNumTarget(data.t[i][j],rpp.track,info,data.pich,data.option)
            if(c1==false or c1==0)then break end

            if(t~=nil)then  track=t end

            local range=data.range
            if(range==0)then
                range= rpp.track[track].item[c1].length
            end
            local tp=  math.min( (time - rpp.track[track].item[c1].pos)/range ,1)

            local pi = s2nc(data.p[i],c2)
            local hi = s2nc(data.h[i],c2)
           
            local av=tiv(hi,rpp.track[track].item[c2],c2,data.v[i])
            local bv=0
            if(pi=="3")then
                bv,av=av,0 --入れ替え
            elseif(pi=="4")then --前の値を計算
                if(c1-1~=0)then
                    if (data.pich==0 or(rpp.track[track].item[c1].pich~=rpp.track[track].item[c1-1].pich ))then
                        c2=c2-1
                    end
                    if(c2~=0)then
                        hi = s2nc(data.h[i],c2)
                        bv=tiv(hi,rpp.track[track].item[c2],c2,data.v[i])
                    end
                end
            end
            if(data.e[i]~=1)then
                tp=math.min(math.max(tp,0),1)
            end
            pos[i] = pos[i] + ( typeAtoB(pi,bv,av,tp,getEasing(data.e[i])) or 0 )
        end
    end
    return pos
end

---RtAv2(エフェクト)@拡大率などで使う関数
---@param rpp table
---@param info table
---@param data table
---@return table
local function getZoom(rpp,info,data)
    local s2nc=stringCycle--string2numberCycle
    local tiv=typeItemZoomValue
    local track=info.track
    local time=info.time
    local pos={}
    for i=1,#data.p do
        pos[i]=1
        for j=1,#data.t[i] do
 
            local c1,c2=timeItemNumTarget(data.t[i][j],rpp.track,info,data.pich,data.option)
            if(c1==false or c1==0)then break end


            local range=data.range
            if(range==0)then
                range= rpp.track[track].item[c1].length
            end
            local tp= math.min( (time - rpp.track[track].item[c1].pos)/range ,1)

            local pi = s2nc(data.p[i],c2)
            local hi = s2nc(data.h[i],c2)
           
            local av=tiv(hi,rpp.track[track].item[c2],c2,data.v[i])
            local bv=1
            if(pi=="3")then
                bv,av=av,1 --入れ替え
            elseif(pi=="4")then --前の値を計算
                if(c1-1~=0)then
                    if (data.pich==0 or(rpp.track[track].item[c1].pich~=rpp.track[track].item[c1-1].pich ))then
                        c2=c2-1
                    end
                    if(c2~=0)then
                        hi = s2nc(data.h[i],c2)
                        bv=tiv(hi,rpp.track[track].item[c2],c2,data.v[i])
                    end
                end
            end
            if(data.e[i]~=1)then
                tp=math.min(math.max(tp,0),1)
            end
            print((typeAtoB(pi,bv,av,tp,getEasing(data.e[i])) or 1))
            pos[i] = pos[i] *  (typeAtoB(pi,bv,av,tp,getEasing(data.e[i])) or 1)
        end
      --  pos[i]=ZOOM(pos[i])
    end
    return pos
end

--行列計算
local function gyoretu(a,b)
    local c={}
    for i=1,3 do
        c[i]={}
        for j=1,3 do
            c[i][j]=0
            for k=1,3 do
                c[i][j]=c[i][j] + a[i][k]*b[k][j]
            end
        end
    end
    return c
end

--xyzをrx,ry,rz回転させた後の座標を計算
local function rotationPos0(x,y,z,rx,ry,rz)
    local rxr=math.rad( rx or 0)
    local ryr=math.rad( ry or 0)
    local rzr=math.rad( rz or 0)
    if(rxr==0 and ryr==0 and rzr==0)then
        return x,y,z
    end
    local a={ {1            ,0             ,0            },  
        {0            ,math.cos(rxr) ,math.sin(rxr)},  
        {0            ,-math.sin(rxr),math.cos(rxr)} }

        local b={ {math.cos(ryr),0            ,-math.sin(ryr)},  
        {0            ,1            ,0             },  
        {math.sin(ryr), 0           ,math.cos(ryr) } }

        local c={ {math.cos(rzr) ,math.sin(rzr),0            },  
        {-math.sin(rzr),math.cos(rzr),0            },  
        {0             ,0            ,1            } }
    local d
    if(rxr~=0 and ryr~=0)then
        d=gyoretu(a,b)
    elseif(rxr~=0 and rzr~=0)then
        d=gyoretu(a,c)
    elseif(ryr~=0 and rzr~=0)then
        d=gyoretu(b,c)
    elseif(rxr~=0 or rzr~=0)then
        d=gyoretu(a,c)
    elseif(ryr~=0)then
        d=gyoretu(a,b)
    else
        d=gyoretu(c,gyoretu(a,b))
    end
    local posx = d[1][1]*x + d[1][2]*y + d[1][3]*z
    local posy = d[2][1]*x + d[2][2]*y + d[2][3]*z
    local posz = d[3][1]*x + d[3][2]*y + d[3][3]*z
    return posx,posy,posz
end
--xyzをrx,ry,rz回転させた後の座標を計算(Exedit)
local function rotationPos(x,y,z,rx,ry,rz)
    x,y,z=rotationPos0(x,y,z,0,0,-rz)
    x,y,z=rotationPos0(x,y,z,-rx,-ry,0)
    return x,y,z
end

---Exeditの変数を加味したobj.draw
---@param x_ any
---@param y_ any
---@param z_ any
---@param zm_ any
---@param a_ any
---@param rx_ any
---@param ry_ any
---@param rz_ any
local function draw(x_,y_,z_,zm_,a_,rx_,ry_,rz_)
    local x=x_ or obj.ox
    local y=y_ or obj.oy
    local z=z_ or obj.oz

    local zm=zm_ or obj.zoom
    local a=a_ or obj.alpha

    local rx=rx_ or obj.rx
    local ry=ry_ or obj.ry
    local rz=rz_ or obj.rz
    local at = obj.aspect

    local zx,zy=1,1
    if(at>0)then
        zx=1
        zy=at-1
    elseif(at<0)then
        zy=1
        zx=(at*-1)-1
    end
  
    local w,h=zm*(obj.w*zx)/2,zm*(obj.h*zy)/2
    obj.setoption("drawtarget","tempbuffer",obj.w,obj.h)
    local x0,y0,z0 = rotationPos(-w+x,-h+y,0+z,rx,ry,rz)
    local x1,y1,z1 = rotationPos( w+x,-h+y,0+z,rx,ry,rz)
    local x2,y2,z2 = rotationPos( w+x, h+y,0+z,rx,ry,rz)
    local x3,y3,z3 = rotationPos(-w+x, h+y,0+z,rx,ry,rz)

    

    obj.drawpoly(
        x0,y0,z0,
        x1,y1,z1,
        x2,y2,z2,
        x3,y3,z3,
        0,0,obj.w,0,obj.w,obj.h,0,obj.h,
        a
   )
    obj.setoption("drawtarget","framebuffer")
    obj.load("tempbuffer")
end



---テキストを表示
---@param str string 文字
local function loadText(str)
    obj.setfont("メイリオ",50,4,0xffffff,0)
    obj.setoption("billboard",3)
    obj.load("text",str)
    obj.draw(-obj.x,-obj.y,-obj.z,1,1,-obj.rx,-obj.ry,-obj.rz)
end








local M = {
    timeItemNum=timeItemNum,
    timeItemNumPich=timeItemNumPich,
    itemNumPich=itemNumPich,
    string2number=string2number,
    s2n=string2number,
    stringCycleNum=stringCycleNum,
    string2numberCycle=string2numberCycle,
    stringCycle=stringCycle,
    s2nc=string2numberCycle,
    typeItemValue=typeItemValue,
    timeItemNumTarget=timeItemNumTarget,
    RtAv2DataInit=RtAv2DataInit,
    addFunction=addFunction,
    addFirstFunction= addFirstFunction,
    addDrawFunction=addDrawFunction,
    setDrawNum=setDrawNum,
    setPichNum=setPichNum,
    setLengthNum=setLengthNum,
    AtoB=AtoB,
    typeAtoB=typeAtoB,
    getEasing=getEasing,
    getXYZ=getXYZ,
    getZoom=getZoom,
    rotationPos=rotationPos,
    draw=draw,
    loadText=loadText,
    ZOOM=ZOOM,
    ALPHA=ALPHA
}

setmetatable(M, {
    __index = function(t, k)
        if k == "RtAv2Data" then
            return RtAv2Data
        end
        return rawget(t, k)
    end,
    __newindex = function(t, k, v)
        if k == "RtAv2Data" then
            RtAv2Data = v
        else
            rawset(t, k, v)
        end
    end
})

return M