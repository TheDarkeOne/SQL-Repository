use f19AmmonZ

--Create the Procedure for inserting a contact and the contact table
go

drop table Contacts

create table Contacts (
	ContactId int primary key identity(1,1),
	FirstName varchar(40) not null,
	LastName varchar(40) not null,
	DateOfBirth Date,
	AllowContactByPhone Bit not null,
	CreatedDate datetime not null
)

drop procedure InsertContact

go

create procedure dbo.InsertContact
(
	@firstName varchar(40),
	@lastName  varchar(40),
	@dateOfBirth Date = NULL,
	@allowContactByPhone Bit,
	@contactID int output
)
as
begin;

set nocount on;

IF NOT EXISTS ( select 1 from Contacts where FirstName = @firstName AND LastName = @lastName AND DateOfBirth = @dateOfBirth)
begin;
	insert into Contacts (FirstName, LastName, DateOfBirth, AllowContactByPhone, CreatedDate) 
		values (@firstName, @lastName, @dateOfBirth, @allowContactByPhone, SYSDATETIME())

	Select @ContactID = SCOPE_IDENTITY();

end;
EXEC SelectContact @contactID = @ContactID

set nocount off;
end;


--Test that the procedure works
go

Declare @RetVal INT;

EXEC InsertContact
@firstName = 'John',
@lastName = 'JingleHeimer',
@DateOfBirth = '2001-06-09',
@allowContactByPhone = 0,
@ContactID = @RetVal OUTPUT;

select * from Contacts where LastName = 'JingleHeimer';

