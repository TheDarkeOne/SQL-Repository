Use GasHistory

Drop Table GasTable
Drop Table Car
Drop Table  GasType

CREATE TABLE Car(
    ID int NOT NULL PRIMARY KEY,
	CarType VARCHAR(40) NOT NULL,
	Miles FLOAT ,
    MilesPerGallon FLOAT
) ON [PRIMARY]
GO

CREATE TABLE GasType(
	ID int NOT NULL PRIMARY KEY,
	GasType VARCHAR(40) NOT NULL,
	PricePerGallon Float
) ON [PRIMARY]
GO

CREATE TABLE GasTable(
	ID int NOT NULL,
	cost FLOAT,
	car_Id int NOT NULL,
	gas_Id int NOT NULL,
	gallons Float,
	past_miles int,
	current_miles int,
	dayStarted DATETIME,
	dayEnded DATETIME,
 CONSTRAINT [PK_zEffectiveBidHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE GasTable WITH CHECK ADD CONSTRAINT [FK_GasHistory_Car] FOREIGN KEY(car_Id)
REFERENCES Car (ID)
GO

ALTER TABLE GasTable WITH CHECK ADD CONSTRAINT [FK_GasHistory_GasType] FOREIGN KEY (gas_Id)
REFERENCES GasType (ID)
GO

DELETE from Car

insert into Car (
ID,CarType,Miles,MilesPerGallon )
values 
(1,'Mazda 3 2003',200000,30.5),
(2,'Ford F150',100000,24.75),
(3,'Fictional Car',10000,300),
(4,'BadCar',300000,15.45)

select * from Car

DELETE from GasType

insert into GasType (
ID,GasType,PricePerGallon)
values 
(1,'95 Unleaded',2.45),
(2,'97 Medium',2.50),
(3,'99 Premium',2.75),
(4,'Diesel',3.00)

select * from GasType
GO
create trigger GasTableTrigger
on GasTable
AFTER INSERT
as
begin
    DECLARE @OldMPG FLOAT
    DECLARE @NewMPG FLOAT
    DECLARE @TempMiles FLOAT
    DECLARE @TempGallons FLOAT
    DECLARE @TempMPG FLOAT
    Declare @ID INT

    SET @TempMiles = (select current_miles from inserted)
    SET @TempGallons = (select gallons from inserted)
    Set @TempMPG = @TempMiles/@TempGallons
    SET @ID = (select car_Id from inserted)
    SET @OldMPG = (select MilesPerGallon from Car where ID = @ID)
    Set @NewMPG = ((@TempMPG + @OldMPG)/2)

    UPDATE Car 
    SET 
        MilesPerGallon = @NewMPG
    WHERE
        ID = @ID;  
end
GO

Select * from Car where ID = 1

insert into GasTable (ID,cost,car_Id,gas_Id,gallons,past_miles,current_miles,dayStarted,dayEnded) values
(1,30.00,1,4,10,600.4,290.5,SYSDATETIME(),SYSDATETIME());

Select * from Car where ID = 1
