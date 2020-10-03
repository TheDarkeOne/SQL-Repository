use f19AmmonZ

--Start of the creation of the zBay tables
CREATE TABLE [dbo].[zBidIncrement](
	[lowAmt] [money] NOT NULL,
	[highAmt] [money] NOT NULL,
	[increment] [money] NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[zAuction](
	[ID] [int] NOT NULL,
	[description] [varchar](8000) NULL,
	[title] [varchar](200) NOT NULL,
	[startingBidAmt] [money] NOT NULL,
	[effectiveBidAmt] [money] NULL,
	[effectiveBidderID] [int] NULL,
 CONSTRAINT [PK_zAuction] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[zUser](
	[ID] [int] NOT NULL,
	[name] [varchar](80) NULL,
	[phone] [varchar](15) NULL,
	[rating] [char](1) NULL,
 CONSTRAINT [PK_zUser] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[zBidLimits](
	[ID] [int] NOT NULL,
	[Auction_ID] [int] NOT NULL,
	[User_ID] [int] NOT NULL,
	[bidTime] [datetime] NOT NULL,
	[bidLimit] [money] NOT NULL,
 CONSTRAINT [PK_zBidLimits] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[zBidLimits]  WITH CHECK ADD  CONSTRAINT [FK_zBidLimits_zAuction] FOREIGN KEY([Auction_ID])
REFERENCES [dbo].[zAuction] ([ID])
GO

ALTER TABLE [dbo].[zBidLimits] CHECK CONSTRAINT [FK_zBidLimits_zAuction]
GO

ALTER TABLE [dbo].[zBidLimits]  WITH CHECK ADD  CONSTRAINT [FK_zBidLimits_zUser] FOREIGN KEY([User_ID])
REFERENCES [dbo].[zUser] ([ID])
GO

ALTER TABLE [dbo].[zBidLimits] CHECK CONSTRAINT [FK_zBidLimits_zUser]
GO

CREATE TABLE [dbo].[zEffectiveBidHistory](
	[ID] [int] NOT NULL,
	[Auction_ID] [int] NOT NULL,
	[bidTime] [datetime] NOT NULL,
	[prevBidderID] [int] NULL,
	[prevBidderLimit] [money] NULL,
	[newBidderID] [int] NOT NULL,
	[newBidderLimit] [money] NOT NULL,
	[Increment] [money] NULL,
	[newEffectiveBidderID] [int] NOT NULL,
	[newEffectiveBidAmt] [money] NOT NULL,
	[comment] [varchar](100) NULL,
 CONSTRAINT [PK_zEffectiveBidHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[zEffectiveBidHistory]  WITH CHECK ADD  CONSTRAINT [FK_zEffectiveBidHistory_zAuction] FOREIGN KEY([Auction_ID])
REFERENCES [dbo].[zAuction] ([ID])
GO

ALTER TABLE [dbo].[zEffectiveBidHistory] CHECK CONSTRAINT [FK_zEffectiveBidHistory_zAuction]
GO

ALTER TABLE [dbo].[zEffectiveBidHistory]  WITH CHECK ADD  CONSTRAINT [FK_zEffectiveBidHistory_zUser] FOREIGN KEY([prevBidderID])
REFERENCES [dbo].[zUser] ([ID])
GO

ALTER TABLE [dbo].[zEffectiveBidHistory] CHECK CONSTRAINT [FK_zEffectiveBidHistory_zUser]
GO

--Populates the tables with default data
insert into zBidIncrement (
lowAmt,highAmt,increment )
values 
(0.01,0.99,0.05)
,(1,4.99,0.25)
,(5,24.99,0.5)
,(25,99.99,1)
,(100,249.99,2.5)
,(250,499.99,5)
,(500,999.99,10)
,(1000,2499.99,25)
,(2500,4999.99,50)
,(5000,999999999999.99,100)

insert into zAuction (id,description,title,startingBidAmt,effectiveBidAmt,effectiveBidderID) values
(1,'Antique oak sitting chair.  Dual rockers.  Excellent wear and comfort.','Wooden Chair',0.01,null,null),
(2,'Unwrapped.  Still new!  Blue color, original Tootsie roll pop.','Tootsie Roll Lollipop',0.25,null,null)

insert into zUser (id,name,phone,rating) values
(70,'Heber Allen','435-283-7532','A'),
(71,'Bob Alexander','435-435-4355','B'),
(72,'Sally Salamander','801-801-8011','A'),
(73,'Robert Romeo','408-408-4088','A')

/*drop table zUser
drop table zAuction
drop table zBidIncrement
drop table zBidLimits
drop table zEffectiveBidHistory
drop Trigger zBidTrigger*/

--Start of the trigger for the zBidLimits table
create trigger zBidTrigger 
on zBidLimits
for INSERT
as
begin
	
	/*with m as (select bidLimit from inserted), 
		 h as (select effectiveBidAmt from zAuction z where z.ID = (select Auction_ID from INSERTED)
	*/
	Declare @bid money 
	Declare @highBid money
	Declare @bidInc money
	Declare @bidLimit money
	Declare @auctionID int
	Declare @bidderID int
	Declare @currAuction int
	Declare @effectiveBid money
	Declare @bidTime DateTime
	Declare @rowId int
	
	set @bid = (select bidLimit from inserted)	
	set @highBid = (select top(1) iif(z.newBidderLimit <= z.prevBidderLimit, z.prevBidderLimit, z.newBidderLimit) from zEffectiveBidHistory z where z.Auction_ID = (select Auction_ID from INSERTED) AND comment = 'Valid' order by bidTime desc)
	set @auctionID = (select Auction_ID from inserted)
	set @bidderID = (select User_ID from inserted)
	set @effectiveBid = (Select z.effectiveBidAmt from zAuction z where z.ID = @AuctionID)
	set @bidTime = (select bidTime from inserted)
	set @rowId = (select count(*) from zEffectiveBidHistory) + 1

	/*Check to see if the auction is in the history table*/
	if(@effectiveBid is null)
	Begin
		update zAuction set effectiveBidderID = @bidderID where id = @auctionID
		update zAuction set effectiveBidAmt = startingBidAmt where id = @auctionID

		set @highBid = (select effectiveBidAmt from zAuction z where z.ID = (select Auction_ID from INSERTED))
		set @bidInc = (select z.increment from zBidIncrement z where @highBid >= z.lowAmt AND @highBid <= z.highAmt)

		insert into zEffectiveBidHistory (id, Auction_ID, bidTime, newBidderID, newBidderLimit, increment, newEffectiveBidderID, newEffectiveBidAmt, comment)
			select @rowid, @auctionID, @bidTime, @bidderID, @bid, @bidInc, @bidderID, za.startingBidAmt, 'Valid'
				from zAuction za
				where za.id = @AuctionID
				group by za.id, za.startingBidAmt

		return
	End

	/*Check to see if the bid is valid */
	if(@bid > @effectiveBid)
	Begin		

		/*Check if the bid is greater then the current high bid */
		if(@bid > @highBid)
		Begin
			
			set @bidInc = (select z.increment from zBidIncrement z where @highBid >= z.lowAmt AND @highBid <= z.highAmt)
			set @bidLimit = (select top(1) zbh.newBidderLimit from zEffectiveBidHistory zbh where zbh.Auction_ID =  @auctionID order by zbh.bidTime desc)
			set @bidInc = (select z.increment from zBidIncrement z where @bidLimit >= z.lowAmt AND @bidLimit <= z.highAmt)
			
			insert into zEffectiveBidHistory (id, Auction_ID, bidTime, prevBidderID, prevBidderLimit, newBidderID, newBidderLimit, Increment, newEffectiveBidderID, newEffectiveBidAmt, comment)
				select top(1) @rowId, @auctionID, @bidTime, za.effectiveBidderID, zbh.newBidderLimit, @bidderID, @bid, @bidInc, @bidderID, (@highBid +  @bidInc), 'Valid'
					from zAuction za
						inner join zEffectiveBidHistory zbh on
						(za.ID = zbh.Auction_ID)
						where za.id = @AuctionID
						group by za.startingBidAmt, za.effectiveBidderID, za.effectiveBidAmt, zbh.newBidderLimit, zbh.bidTime
						order by zbh.bidTime			

			update zAuction set effectiveBidAmt = @highBid + @bidInc where id = @auctionID
			update zAuction set effectiveBidderID = @bidderID where id = @auctionID

		End
		/*Bid is not greater then the high */
		else
		Begin

			/* set bid increment to correct value from range */
			set @bidInc = (select z.increment from zBidIncrement z where @bid >= z.lowAmt AND @bid <= z.highAmt)

			/*Check if the bid + increment is greater than or equal to high bid */
			if((@bid + @bidInc) >= @highBid)
			Begin

				set @bidLimit = (select top(1) zbh.newBidderLimit from zEffectiveBidHistory zbh where zbh.Auction_ID =  @auctionID order by zbh.bidTime desc)
				set @bidInc = (select z.increment from zBidIncrement z where @bidLimit >= z.lowAmt AND @bidLimit <= z.highAmt)

				insert into zEffectiveBidHistory (id, Auction_ID, bidTime, prevBidderID, prevBidderLimit, newBidderID, newBidderLimit, Increment, newEffectiveBidderID, newEffectiveBidAmt, comment)
				select top(1) @rowId, @auctionID, @bidTime, za.effectiveBidderID, zbh.newBidderLimit, @bidderID, @bid, @bidInc, za.effectiveBidderID, @bid, 'Valid'
					from zAuction za
						inner join zEffectiveBidHistory zbh on
						(za.ID = zbh.Auction_ID)
						where za.id = @AuctionID
						group by za.startingBidAmt, za.effectiveBidderID, za.effectiveBidAmt, zbh.newBidderLimit, zbh.bidTime
						order by zbh.bidTime

				update zAuction set effectiveBidAmt = @bid where id = @auctionID

			End
			/*Bid + increment is not greater than or equal to high bid*/
			else
			Begin

				set @bidLimit = (select top(1) zbh.newBidderLimit from zEffectiveBidHistory zbh where zbh.Auction_ID =  @auctionID order by zbh.bidTime desc)
				set @bidInc = (select z.increment from zBidIncrement z where @bidLimit >= z.lowAmt AND @bidLimit <= z.highAmt)

				insert into zEffectiveBidHistory (id, Auction_ID, bidTime, prevBidderID, prevBidderLimit, newBidderID, newBidderLimit, Increment, newEffectiveBidderID, newEffectiveBidAmt, comment)
				select top(1) @rowId, @auctionID, @bidTime, za.effectiveBidderID, zbh.newBidderLimit, @bidderID, @bid, @bidInc, za.effectiveBidderID, (@bid +  @bidInc), 'Valid'
					from zAuction za
						inner join zEffectiveBidHistory zbh on
						(za.ID = zbh.Auction_ID)
						where za.id = @AuctionID
						group by za.startingBidAmt, za.effectiveBidderID, za.effectiveBidAmt, zbh.newBidderLimit, zbh.bidTime
						order by zbh.bidTime

				update zAuction set effectiveBidAmt = (@bid + @bidInc) where id = @auctionID
			End
		End	
	End
	/*Bid is not valid */
	else
	Begin
		set @bidLimit = (select top(1) zbh.newBidderLimit from zEffectiveBidHistory zbh where zbh.Auction_ID =  @auctionID order by zbh.bidTime desc)
		set @bidInc = (select z.increment from zBidIncrement z where @bidLimit >= z.lowAmt AND @bidLimit <= z.highAmt)

		insert into zEffectiveBidHistory (id, Auction_ID, bidTime, prevBidderID, prevBidderLimit, newBidderID, newBidderLimit, Increment, newEffectiveBidderID, newEffectiveBidAmt, comment)
		select top(1) @rowId, @auctionID, @bidTime, za.effectiveBidderID, zbh.newBidderLimit, @bidderID, @bid, @bidInc, za.effectiveBidderID, za.effectiveBidAmt, 'Invalid'
			from zAuction za
			inner join zEffectiveBidHistory zbh on
			(za.ID = zbh.Auction_ID)
			where za.id = @AuctionID
			group by za.startingBidAmt, za.effectiveBidderID, za.effectiveBidAmt, zbh.newBidderLimit, zbh.bidTime
			order by zbh.bidTime
	End
End

insert into zBidLimits (id,Auction_ID,User_ID,bidTime,bidLimit) values
(1,1,70,SYSDATETIME(),10.00);

insert into zBidLimits (id,Auction_ID,User_ID,bidTime,bidLimit) values
(2,1,72,SYSDATETIME(),9.00);

insert into zBidLimits (id,Auction_ID,User_ID,bidTime,bidLimit) values
(3,1,73,SYSDATETIME(),15.00);

select * from zAuction
select * from zEffectiveBidHistory




--Start of doBid procedure
Create sequence zBidRow
start with 1
increment by 1
minvalue 1

drop sequence zBidRow
go

delete from zBidLimits
delete from zEffectiveBidHistory
--drop procedure doBid

create procedure doBid(@newBidAmt money, @newBidderID int, @AuctionID int) 
as
begin

	insert into zBidLimits (id, Auction_ID, User_ID, bidTime, bidLimit)
	values (next value for zBidRow, @AuctionID, @newBidderID, SYSDATETIME(), @newBidAmt)

	begin transaction 
		begin try		
				
			Declare @bid money 
			Declare @highBid money
			Declare @bidInc money
			Declare @bidLimit money
			Declare @bidderID int
			Declare @currAuction int
			Declare @effectiveBid money
			Declare @bidTime DateTime
			Declare @rowId int
			Declare @effectiveID int
			Declare @temp money
			Declare @high money

			set @bid = @newBidAmt
			set @bidderID = @newBidderID
			set @effectiveBid = dbo.getBidLimit(@auctionID)
			set @bidTime = SYSDATETIME()
			set @rowId = (next value for zRow)
			set @highBid = dbo.getHighBid(@auctionID)

			if (Not Exists(select id from zAuction where id = @AuctionID))
			begin
				print('Error: invalid auction id')
				rollback
				return;
			end

			/*Check to see if the auction is in the history table*/
			if(@effectiveBid is null) 
			begin
				Declare @start money
				set @start = dbo.getStartingBid(@auctionID)
				set @bidInc = dbo.getBidIncrement(@start)
		
				exec dbo.updateAuctionDetails @bidderID, @auctionID, @start
				exec dbo.insertEffectiveBidHistory @rowID = @rowID, @auctionID = @auctionID, @bidTime = @bidTime, @prevBidderID = null, @prevBidderLimit = null,
					@newBidderID = @bidderID, @newBidderLimit = @bid, @bidIncrement = @bidInc, @effectiveBidderID = @bidderID, @effectiveBidAmt = @start, @comment = 'Valid'

				print('Congratulations! Your bid of ' + cast(@bid as varchar(10)) + ' is currently effective at ' + cast(@start as varchar(10)) + ' the high bid.')
				commit
				return
			end

			/*Check to see if the bid is valid */
			if(dbo.isValidBid(@bid, @auctionID) = 1)
			begin
				/*Check if the bid is greater then the current high bid */
				if(dbo.isHighBid(@bid, @auctionID) = 1)
				begin
					set @bidInc = dbo.getBidIncrement(@highBid)
					set @effectiveID = dbo.getEffectiveBidderID(@auctionID)
					set @bidLimit = dbo.getBidLimit(@auctionID)
					set @temp =  (@highBid + @bidInc)

					exec dbo.insertEffectiveBidHistory @rowID, @auctionID, @bidTime, @effectiveID, @bidLimit, @bidderID, @bid, @bidInc, @bidderID, @temp, 'Valid'
					exec dbo.updateAuctionDetails @bidderID, @auctionID, @temp
					print('Congratulations! Your bid of ' + cast(@bid as varchar(10)) +' is currently effective at ' + cast(@effectiveBid as varchar(10)) + ' the high bid.')
				end

				/*Bid is not greater then the high */
				else
				begin
					/*Check if the bid + increment is greater than or equal to high bid */
					if(dbo.isHighBid((@bid + dbo.getBidIncrement(@bid)), @auctionID) = 1)
					begin
						set @bidInc = dbo.getBidIncrement(@bid)
						set @effectiveID = dbo.getEffectiveBidderID(@auctionID)
						set @bidLimit = dbo.getBidLimit(@auctionID)

						exec dbo.insertEffectiveBidHistory @rowID, @auctionID, @bidTime, @effectiveID, @bidLimit, @bidderID, @bid, @bidInc, @effectiveID, @bid, 'Valid'
						exec dbo.updateAuctionDetails @effectiveID, @auctionID, @bid
						print('your bid of ' + cast(@bid as varchar(10)) + ' has been outbid')
					end
		
					/*Bid + increment is not greater than or equal to high bid*/
					else
					begin
						set @bidInc = dbo.getBidIncrement(@bid)
						set @effectiveID = dbo.getEffectiveBidderID(@auctionID)
						set @bidLimit = dbo.getBidLimit(@auctionID)
						set @temp =  (@bid + @bidInc)

						exec dbo.insertEffectiveBidHistory @rowID, @auctionID, @bidTime, @effectiveID, @bidLimit, @bidderID, @bid, @bidInc, @effectiveID, @temp, 'Valid'
						exec dbo.updateAuctionDetails @effectiveID, @auctionID, @temp
						print('your bid of ' + cast(@bid as varchar(10)) + ' has been outbid')
					end

				end

			end

			/*Bid is not valid */
			else
			begin
				set @bidInc = dbo.getBidIncrement(@bid)
				set @effectiveID = dbo.getEffectiveBidderID(@auctionID)
				set @effectiveBid = dbo.getEffectiveBid(@auctionID)
				set @bidLimit = dbo.getBidLimit(@auctionID)


				exec dbo.insertEffectiveBidHistory @rowID = @rowID, @auctionID = @auctionID, @bidTime = @bidTime, @prevBidderID = @effectiveID, @prevBidderLimit = @bidLimit, @newBidderID = @bidderID, @newBidderLimit = @bid, @bidIncrement = @bidInc, @effectiveBidderID = @effectiveID, @effectiveBidAmt = @effectiveBid, @comment = 'Invalid'
		
				Declare @bidCount int
				set @bidCount = (select count(*) from zBidLimits)
				delete from zBidLimits where zBidLimits.ID = @bidCount
				print('Sorry your bid is not valid')

			end

			commit

		end try
		begin catch
			rollback
		end catch

end

go

exec doBid 15.00, 73, 10

select * from zEffectiveBidHistory
select * from zBidLimits
select * from zAuction

go

----------------------------------------------------
--Test for invalid auction id
----------------------------------------------------
alter table zBidLimits
noCheck constraint all;

exec doBid 20.00, 73, 100

alter table zBidLimits
with nocheck check constraint all
----------------------------------------------------
--Test result: Print "Error: invalid AuctionID"
----------------------------------------------------

----------------------------------------------------
--Test for winning bid
----------------------------------------------------
exec doBid 30, 71, 1
----------------------------------------------------
--Test result: Print "Congratulations! Your bid of 30 is currently effective at 0.01 the high bid."
----------------------------------------------------

----------------------------------------------------
--Test for non-winning bid
----------------------------------------------------
exec doBid 10, 73, 1
----------------------------------------------------
--Test result: Print "your bid of 10 has been outbid"
----------------------------------------------------

----------------------------------------------------
--Test for failure:zAuction
----------------------------------------------------
alter table zBidLimits
noCheck constraint all;

exec doBid 30, 100, 1

alter table zBidLimits
with nocheck check constraint all
----------------------------------------------------
--Test result: Print "Error: with zAuction - bid rolled back"
----------------------------------------------------

----------------------------------------------------
--Test for failure:zEffectiveHistory
----------------------------------------------------
alter sequence zRow restart with 1
alter table zBidLimits
noCheck constraint all;

exec doBid 30, 71, 1

alter table zBidLimits
with nocheck check constraint all
----------------------------------------------------
--Test result: Print "Error: with zEffectiveBidHistory"
----------------------------------------------------