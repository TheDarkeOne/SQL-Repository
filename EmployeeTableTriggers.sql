Create TRIGGER onDel
on HW_Oct16.Employee
FOR DELETE 
AS 
Begin 
Insert into HW_Oct16.Employee_audit_logs (employee_id, oName, oSal, oBonus, editedBy, editedTime) SELECT d.Employee_ID, d.Name, d.Salary,d.Bonus, ORIGINAL_LOGIN(), GetDate() FROM DELETED d
End

Create TRIGGER onIn
on HW_Oct16.Employee
FOR Insert 
AS 
Begin 
Insert into HW_Oct16.Employee_audit_logs (employee_id, nName, nSal, nBonus, editedBy, editedTime) SELECT i.Employee_ID, i.Name, i.Salary,i.Bonus, ORIGINAL_LOGIN(), GetDate() FROM INSERTED i 
End

Create TRIGGER onUp
on HW_Oct16.Employee
FOR UPDATE 
AS 
Begin 
Insert into HW_Oct16.Employee_audit_logs (employee_id, oName, nName, oSal, nSal, oBonus, nBonus, editedBy, editedTime) SELECT i.Employee_ID, d.Name, i.Name, d.Salary, i.Salary,d.Bonus,i.Bonus, ORIGINAL_LOGIN(), GetDate() FROM DELETED d inner join INSERTED i on (d.Employee_ID = i.Employee_ID)
End

create table HW_Oct16.Employee(
Employee_ID int primary key,
Name varchar(20),
Salary int,
Bonus int
)

create table HW_Oct16.Employee_audit_logs(
employee_id int , --Primary Key
oName varchar(20), --Deleted.Name
nName varchar(20), --Inserted.Name
oSal int, --Deleted.Salary
nSal int, --Inserted.Salary
oBonus int, --Deleted.Bonus
nBonus int, --Inserted.Bonus
editedBy varchar(20), --ORIGINAL_LOGIN()
editedTime datetime2, --GetDate()
primary key(employee_id, editedTime)
)

drop table HW_Oct16.Employee_audit_logs

insert into HW_OCT16.Employee values (1,'Stephen',10000,500),(2,'Bob',8000,250);

update HW_OCT16.Employee set Bonus=888 where Employee_ID=1;

update HW_OCT16.Employee set Bonus=999 where Employee_ID=1;

update HW_OCT16.Employee set Bonus=333 where Employee_ID=2;

delete from HW_OCT16.Employee where Employee_ID=2;

select * from HW_Oct16.Employee_audit_logs order by HW_Oct16.Employee_audit_logs.editedTime
