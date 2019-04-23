--------------------------------
if not exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME = N'Documents' and TABLE_SCHEMA = N'a2tutorial')
begin
	create table a2tutorial.Documents (
		Id bigint identity(100,1) not null constraint PK_Documents primary key,
		Kind nchar(2),
		[No] nvarchar(128),
		[Date] datetime,
		[Supplier] bigint null constraint FK_Documents_Supplier_Agents references a2tutorial.Agents(Id),
		Memo nvarchar(255),
		LastModifiedDate datetime not null constraint DF_DocumentsLastModifiedDate default(getdate()),
		LastModifiedUser bigint not null constraint FK_Documents_LastModifiedUser_Users references a2security.Users(Id)
		);
end
go
--------------------------------
if not exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME = N'Details' and TABLE_SCHEMA = N'a2tutorial')
begin
	create table a2tutorial.Details (
		Id bigint identity(100,1) not null constraint PK_Details primary key,
		[Document] bigint null constraint FK_Details_Document_Documents references a2tutorial.Documents(Id),
		[Product] bigint null constraint FK_Details_Product_Entities references a2tutorial.Entities(entId),
		Price float,
		Qty float,
		[Sum] money
	);
end
go
--------------------------------
create or alter procedure a2tutorial.[Document.Index]
@UserId bigint,
@Kind nchar(2)
as
begin
	set nocount on;
	select [Documents!TDocument!Array] = null, [Id!!Id] = d.Id, [Date], Kind, d.Memo, LastModifiedDate,
		[User.Id!TUser!Id] = u.Id, [User.Name!TUser] = u.UserName
	from a2tutorial.Documents d
		left join a2security.Users u on d.LastModifiedUser = u.Id
	where Kind = @Kind
	order by d.Id desc;

end
go
--------------------------------
create or alter procedure a2tutorial.[Document.Load]
@UserId bigint,
@Id bigint = null,
@Kind nchar(2)
as
begin
	set nocount on;
	select [Document!TDocument!Object] = null, [Id!!Id] = d.Id, [Date], Kind, d.Memo, LastModifiedDate,
		[User.Id!TUser!Id] = u.Id, [User.Name!TUser] = u.UserName,
		[Supplier!TAgent!RefId] = d.Supplier,
		[Rows!TRow!Array] = null
	from a2tutorial.Documents d
		left join a2security.Users u on d.LastModifiedUser = u.Id
	where Kind = @Kind and d.Id = @Id;

	select [!TAgent!Map] = null, [Id!!Id] = Id, Code, [Name], [Memo]
	from a2tutorial.Agents where Id in (select Supplier from a2tutorial.Documents where Id=@Id);

	select [!TRow!Array] = null, [Id!!Id] = Id, [!TDocument.Rows!ParentId] = Document, 
		[Product!TProduct!RefId] = Product, Price, Qty, [Sum]
	from a2tutorial.Details where Document = @Id;

	select [!TProduct!Map] = null, [Id!!Id] = entId, [Name] = entName, [Memo], Article = artNo 
	from a2tutorial.Entities e where entId in (select Product from a2tutorial.Details where Document=@Id);
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2tutorial' and ROUTINE_NAME=N'Document.Update')
	drop procedure a2tutorial.[Document.Update]
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2tutorial' and ROUTINE_NAME=N'Document.Metadata')
	drop procedure a2tutorial.[Document.Metadata]
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2tutorial' and DOMAIN_NAME=N'Document.TableType' and DATA_TYPE=N'table type')
	drop type a2tutorial.[Document.TableType];
go
------------------------------------------------
create type a2tutorial.[Document.TableType]
as table(
	Id bigint null,
	[Date] datetime,
	[Memo] nvarchar(255),
	Supplier bigint
)
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2tutorial' and DOMAIN_NAME=N'Detail.TableType' and DATA_TYPE=N'table type')
	drop type a2tutorial.[Detail.TableType];
go
------------------------------------------------
create type a2tutorial.[Detail.TableType]
as table(
	Id bigint null,
	[ParentId] bigint,
	[Product] bigint,
	Price float,
	Qty float,
	[Sum] money
)
go

------------------------------------------------
create or alter procedure a2tutorial.[Document.Metadata]
as
begin
	set nocount on;
	declare @Doc a2tutorial.[Document.TableType];
	declare @Rows a2tutorial.[Detail.TableType];
	select [Document!Document!Metadata] = null, * from @Doc;
	select [Rows!Document.Rows!Metadata] = null, * from @Rows;
end
go


------------------------------------------------
create or alter procedure a2tutorial.[Document.Update]
@UserId bigint,
@Kind nchar(2),
@Document a2tutorial.[Document.TableType] readonly,
@Rows a2tutorial.[Detail.TableType] readonly
as
begin
	set nocount on;
	--declare @xml nvarchar(max);
	--select @xml = (select * from @Rows for xml auto);
	--throw 60000, @xml, 0;

	declare @output table(op nvarchar(150), id bigint);
	declare @RetId bigint;

	merge a2tutorial.Documents as target
	using @Document as source
	on (target.Id = source.Id)
	when matched then
		update set 
			target.[Date] = source.[Date],
			target.[Supplier] = source.[Supplier],
			target.[Memo] = source.[Memo],
			target.LastModifiedDate = getdate(),
			target.LastModifiedUser = @UserId
	when not matched by target then 
		insert (Kind, [Date], [Supplier], Memo, LastModifiedUser)
		values (@Kind, [Date], [Supplier], Memo, @UserId)
	output 
		$action op,
		inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	merge a2tutorial.Details as target
	using @Rows as source
	on (target.Id = source.Id and target.Document = @RetId)
	when matched then 
		update set
			target.Product = source.Product,
			target.Qty = source.Qty,
			target.Price = source.Price,
			target.[Sum] = source.[Sum]
	when not matched by target then
		insert (Document, Product, Qty, Price, [Sum])
		values (@RetId, Product, Qty, Price, [Sum])
	when not matched by source and target.Document = @RetId then delete;

	exec a2tutorial.[Document.Load] @UserId, @RetId, @Kind
end
go
--insert into a2tutorial.Documents(Kind, [Date], LastModifiedUser) values (N'IN', getdate(), 99)

/*
update a2tutorial.Documents set Supplier = 103 where Id = 100

select * from a2tutorial.Documents
select * from a2tutorial.Agents


*/

--insert into a2tutorial.Details(Document, Product, Qty, Price, [Sum]) values (100, 101, 1, 1, 1);








