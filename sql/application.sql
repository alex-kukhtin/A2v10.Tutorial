
------------------------------------------------
if not exists(select * from a2sys.SysParams where [Name]= N'AppTitle')
	insert into a2sys.SysParams([Name], StringValue) values (N'AppTitle', N'A2v10');
go
------------------------------------------------
if not exists(select * from a2sys.SysParams where [Name]= N'AppSubTitle')
	insert into a2sys.SysParams([Name], StringValue) values (N'AppSubTitle', N'tutorial');
go

------------------------------------------------
if not exists(select * from a2security.Users where Id <> 0)
begin
	set nocount on;
	-- Password = "Admin"
	insert into a2security.Users(Id, UserName, SecurityStamp, PasswordHash, PersonName, EmailConfirmed)
	values (99, N'admin@admin.com', N'c9bb451a-9d2b-4b26-9499-2d7d408ce54e', N'AJcfzvC7DCiRrfPmbVoigR7J8fHoK/xdtcWwahHDYJfKSKSWwX5pu9ChtxmE7Rs4Vg==',
		N'System administrator', 1);
	insert into a2security.UserGroups(UserId, GroupId) values (99, 77), (99, 1); /*predefined values*/
end
go
------------------------------------------------
if not exists (select * from a2security.Acl where [Object] = 'std:menu' and [ObjectId] = 1 and GroupId = 1)
begin
	insert into a2security.Acl ([Object], ObjectId, GroupId, CanView)
		values (N'std:menu', 1, 1, 1);
end
go
------------------------------------------------
begin
	set nocount on;
	-- create admin menu
	declare @menu table(id bigint, p0 bigint, [name] nvarchar(255), [url] nvarchar(255), icon nvarchar(255), [order] int);
	insert into @menu(id, p0, [name], [url], icon, [order])
	values
		(1, null, N'Main',        null,         null,    0),
		(10,   1, N'Справочники', N'catalog',   null,   10),
		(20,   1, N'Документы',   N'document',  null,   20),
		(100, 10, N'Контрагенты', N'agent',   N'users', 10);
			
	merge a2ui.Menu as target
	using @menu as source
	on target.Id=source.id and target.Id >= 1 and target.Id < 1000
	when matched then
		update set
			target.Id = source.id,
			target.[Name] = source.[name],
			target.[Url] = source.[url],
			target.[Icon] = source.icon,
			target.[Order] = source.[order]
	when not matched by target then
		insert(Id, Parent, [Name], [Url], Icon, [Order]) values (id, p0, [name], [url], icon, [order])
	when not matched by source and target.Id >= 1 and target.Id < 1000 then 
		delete;
	exec a2security.[Permission.UpdateAcl.Menu];
end
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2tutorial')
begin
	exec sp_executesql N'create schema a2tutorial';
end
go
------------------------------------------------
grant execute on schema ::a2tutorial to public;
go


