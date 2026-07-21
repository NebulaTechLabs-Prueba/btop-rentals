-- BTOP Rentals — seed (real inventory + settings). Idempotent.
-- Applied to the live project on 2026-07-21; kept here for reproducibility.

insert into public.fleet_units (id,plate,name,category,year,make,model,daily,weekly,monthly,deposit_daily,deposit_weekly,deposit_monthly,mile_daily,mile_weekly,mile_monthly,mile_tiers,fuel_type,specs) values
('u990','990','Ottawa Yard Spotter','Yard Spotter',2007,'Ottawa','YT30',250,1000,3800,200,500,500,0,0,0,'[]','Diesel',jsonb_build_object('transmission','Allison Automatic','shortDesc','YT30 4x2 spotter truck · Cummins diesel · Allison automatic · 295/75R22.5 hydraulic-lift 5th wheel.')),
('u17137','17137','Freightliner Cascadia','Daycab',2017,'Freightliner','Cascadia T/A Day Cab',165,875,3600,200,500,1200,0,0,0,'[]','Diesel',jsonb_build_object('transmission','10-Speed Automatic','shortDesc','Detroit DD13 12.8L 410hp · 10-speed automatic · air-ride 275/80R22.5 · A/C.')),
('u16000','16000','Freightliner Cascadia','Daycab',2016,'Freightliner','Cascadia T/A Day Cab',165,875,3600,200,500,1200,0,0,0,'[]','Diesel',jsonb_build_object('transmission','10-Speed Manual','shortDesc','Detroit DD13 12.8L 410hp · 10-speed manual · air-ride 275/80R22.5 · A/C.')),
('u1317','1317','Ram 1500 Tradesman','Pickup',2014,'Ram','1500 Tradesman 4x2',50,300,1000,200,300,500,0,0,0,'[]','Gasoline',jsonb_build_object('transmission','Automatic','shortDesc','2-door · 5.7 V8 gasoline · A/C · spray-on bed liner · 6,600lb GVWR · 8ft bed.')),
('u1212','1212','GMC 3500 Box Truck','Box Truck',2020,'GMC','3500 16ft',60,300,1300,100,150,500,0.15,0.15,0.15,'[{"upTo":200,"rate":0.15},{"upTo":0,"rate":0.10}]','Gasoline',jsonb_build_object('transmission','Automatic','shortDesc','4x2 V8 6.0 gasoline · 12,300 GVWR · Supreme Corp 16ft box · walk-in ramp.')),
('u1116','1116','Mitsubishi Forklift','Forklift',2016,'Mitsubishi','FG25N',180,540,1620,200,300,500,0,0,0,'[]','LP Gas',jsonb_build_object('eqCapacity','5,000 lbs','shortDesc','5,000lb capacity · 3-stage mast · side shift.')),
('u6049','6049','Industrias Loading Ramp','Loading Ramp',2025,'Industrias America','R820',350,1100,3000,200,500,700,0,0,0,'[]','—',jsonb_build_object('shortDesc','96in x 21ft · 32,000lb capacity loading ramp.')),
('u0330','0330','Vermeer RTX200 Trencher','Trencher',2020,'Vermeer','RTX200',225,750,2100,100,350,700,0,0,0,'[]','Gasoline',jsonb_build_object('shortDesc','Walk-behind trencher · Kohler 2-cyl gasoline · hydrostatic drive · 3in x 3ft chain · 8in rubber tracks.')),
('u5555','5555','Movincool ClimatePro12 A/C','Air Conditioning',2019,'Movincool','ClimatePro12',175,550,1650,70,250,700,0,0,0,'[]','Electric',jsonb_build_object('shortDesc','Portable spot air conditioning unit.')),
('u1111','1111','Haul Master Appliance Dolly','Dolly',2020,'Haul Master','600LB',20,60,150,7,25,70,0,0,0,'[]','—',jsonb_build_object('shortDesc','600lb appliance hand truck · heavy-duty strap & crank · solid rubber wheels · stair climbers · fold-out box lifter.')),
('u0410','0410','Nilfisk Liberty SC60 Scrubber','Floor Scrubber',2022,'Nilfisk','Liberty SC60',325,975,2900,150,400,1200,0,0,0,'[]','Electric',jsonb_build_object('shortDesc','Ride-on electric floor scrubber · 24V battery · 32–36in width · up to 70gal tanks · dual-disk brakes.'))
on conflict (id) do nothing;

insert into public.fleet_units (id,plate,name,category,year,make,model,daily,weekly,monthly,deposit_daily,deposit_weekly,deposit_monthly,fuel_type,specs)
select 'u0717_'||g,'0717-'||g,'Starvox XLC-500B Concrete Saw','Concrete Saw',2026,'Starvox','XLC-500B',150,500,1500,50,150,400,'Gasoline',jsonb_build_object('shortDesc','Walk-behind saw · 15in max blade · 7in max cutting depth · manual raise/lower · Loncin 15hp gasoline.')
from generate_series(1,2) g on conflict (id) do nothing;
insert into public.fleet_units (id,plate,name,category,year,make,model,daily,weekly,monthly,deposit_daily,deposit_weekly,deposit_monthly,fuel_type,specs)
select 'u3333_'||g,'3333-'||g,'Igloo Polar 120 Qt Cooler','Cooler',2023,'Igloo','Polar 120Qt',20,80,100,10,20,50,'—',jsonb_build_object('shortDesc','120-quart cooler.')
from generate_series(1,2) g on conflict (id) do nothing;
insert into public.fleet_units (id,plate,name,category,year,make,model,daily,weekly,monthly,deposit_daily,deposit_weekly,deposit_monthly,fuel_type,specs)
select 'u3287_'||g,'3287-'||g,'Forklift Propane Tank','Propane Tank',2023,'Generic','Aluminum w/Gauge',10,25,70,5,15,40,'—',jsonb_build_object('shortDesc','Aluminum forklift propane tank cylinder with gauge.')
from generate_series(1,15) g on conflict (id) do nothing;

insert into public.storage_spaces (id,name,type,size,custom_size,max_weight,surface,location,access,branch,daily,weekly,monthly,deposit,status,inventory_enabled,total_stock,notes) values
('s7777','Warehouse Yard – Trailer Parking','Outdoor','Custom','Trailer space','—','Concrete','Laredo Yard','24/7','Laredo',15,75,150,0,'available',true,160,'Trailer parking only.')
on conflict (id) do nothing;

insert into public.settings (key,value) values
('company', jsonb_build_object('name','BTOP Rentals','address','9807 Mines Rd #9, Laredo TX 78045','phone','+1 469 690 712','email','btoprentals@gmail.com','hours','Mon–Fri 7AM–6PM · Sat 8AM–2PM')),
('commission_policy', jsonb_build_object('mode','percentage','value',5)),
('contract_policy', jsonb_build_object('sendWhen','both'))
on conflict (key) do nothing;
