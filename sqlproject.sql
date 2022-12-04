create table train(
	train_no integer NOT NULL,
	date DATE NOT NULL,
	ac_no integer,
	sl_no integer,
	ac_avail integer,
	sl_avail integer,
	PRIMARY KEY(train_no,date)
	);

create table ac_berth(
	berth_no integer not null primary key,
	berth_type varchar(2)
	);

insert into ac_berth(berth_no, berth_type)VALUES(1,'LB');
insert into ac_berth(berth_no, berth_type)VALUES(2,'LB');
insert into ac_berth(berth_no, berth_type)VALUES(3,'UB');
insert into ac_berth(berth_no, berth_type)VALUES(4,'UB');
insert into ac_berth(berth_no, berth_type)VALUES(5,'SL');
insert into ac_berth(berth_no, berth_type)VALUES(6,'SU');

insert into ac_berth(berth_no, berth_type)VALUES(7,'LB');
insert into ac_berth(berth_no, berth_type)VALUES(8,'LB');
insert into ac_berth(berth_no, berth_type)VALUES(9,'UB');
insert into ac_berth(berth_no, berth_type)VALUES(10,'UB');
insert into ac_berth(berth_no, berth_type)VALUES(11,'SL');
insert into ac_berth(berth_no, berth_type)VALUES(12,'SU');

insert into ac_berth(berth_no, berth_type)VALUES(13,'LB');
insert into ac_berth(berth_no, berth_type)VALUES(14,'LB');
insert into ac_berth(berth_no, berth_type)VALUES(15,'UB');
insert into ac_berth(berth_no, berth_type)VALUES(16,'UB');
insert into ac_berth(berth_no, berth_type)VALUES(17,'SL');
insert into ac_berth(berth_no, berth_type)VALUES(18,'SU');
	
create table sl_berth(
	berth_no integer not null primary key,
	berth_type varchar(2)
	);

insert into sl_berth(berth_no, berth_type)VALUES(1,'LB');
insert into sl_berth(berth_no, berth_type)VALUES(2,'MB');
insert into sl_berth(berth_no, berth_type)VALUES(3,'UB');
insert into sl_berth(berth_no, berth_type)VALUES(4,'LB');
insert into sl_berth(berth_no, berth_type)VALUES(5,'MB');
insert into sl_berth(berth_no, berth_type)VALUES(6,'UB');
insert into sl_berth(berth_no, berth_type)VALUES(7,'SL');
insert into sl_berth(berth_no, berth_type)VALUES(8,'SU');

insert into sl_berth(berth_no, berth_type)VALUES(9,'LB');
insert into sl_berth(berth_no, berth_type)VALUES(10,'MB');
insert into sl_berth(berth_no, berth_type)VALUES(11,'UB');
insert into sl_berth(berth_no, berth_type)VALUES(12,'LB');
insert into sl_berth(berth_no, berth_type)VALUES(13,'MB');
insert into sl_berth(berth_no, berth_type)VALUES(14,'UB');
insert into sl_berth(berth_no, berth_type)VALUES(15,'SL');
insert into sl_berth(berth_no, berth_type)VALUES(16,'SU');

insert into sl_berth(berth_no, berth_type)VALUES(17,'LB');
insert into sl_berth(berth_no, berth_type)VALUES(18,'MB');
insert into sl_berth(berth_no, berth_type)VALUES(19,'UB');
insert into sl_berth(berth_no, berth_type)VALUES(20,'LB');
insert into sl_berth(berth_no, berth_type)VALUES(21,'MB');
insert into sl_berth(berth_no, berth_type)VALUES(22,'UB');
insert into sl_berth(berth_no, berth_type)VALUES(23,'SL');
insert into sl_berth(berth_no, berth_type)VALUES(24,'SU');




	
create extension if not exists "uuid-ossp";

create table ticket(
	pnr_no  uuid default uuid_generate_v4(),
	primary key(pnr_no),
	couch_type varchar(2),
	no_pass integer,
	train_no integer,
	date DATE,
	FOREIGN KEY(train_no,date)references train(train_no,date)
	);
	
create table passenger(
	pass_id uuid default uuid_generate_v4(),
	primary key(pass_id),
	pnr_no uuid,
	name VARCHAR(20),
	age integer,
	gender VARCHAR(2),
	coach_no varchar(3),
	seat_no integer ,
	FOREIGN KEY(pnr_no)references ticket(pnr_no)
	);

create or replace function check_availability(no_seats integer,trai_no integer,dat DATE,c_type VARCHAR(2))
returns int as $$
declare counter int;
Begin
	counter:=0;
	if c_TYPE LIKE 'A%' then

		select into counter train.ac_avail from train where train.train_no=trai_no and train.date=dat;
		if counter>=no_seats then
			return 1; 
		end if;
		if counter<no_seats then
			return 0;
		end if;
		return -2;
	end if;
	if c_type LIKE 'S%' then
		select into counter train.sl_avail from train where train.train_no=trai_no and train.date=dat;
		if counter>=no_seats then
			return 1;
		end if;
		if counter<no_seats then
			return 0; 
		end if;
		return -2;
	end if;
	return -1;
end;
$$ LANGUAGE plpgsql;

create or replace function update_train()
returns trigger as
$ticket$
begin
	if new.couch_type LIKE 'AC' then
		update train set ac_avail=ac_avail-new.no_pass
		where train_no=new.train_no and date=new.date;
	end if;
	if new.couch_type LIKE 'SL' then
		update train set sl_avail=sl_avail-new.no_pass
		where train_no=new.train_no and date=new.date;
	end if;
return old;
end;
$ticket$ LANGUAGE plpgsql;

create trigger count
after insert on ticket
for each row 
execute procedure update_train();

create or replace function create_ticket(train_no int ,date DATE,type varchar(2),no_pass integer)
returns uuid as $$
declare pnr uuid;
begin
select into pnr uuid_generate_v4();
insert into ticket(pnr_no,train_no,date,couch_type,no_pass)VALUES(pnr,train_no,date,type,no_pass);
return pnr;
end ;
$$ LANGUAGE plpgsql;
		
create or replace function update_pass(train_no1 integer,coach_type varchar(2),dates date,no_pass integer,name varchar(20)[],age integer[],gender varchar(2)[])
returns uuid as $$
declare
pnr uuid;
counter integer:=0;
coach_n varchar(3);
berth integer;
seats_avail integer;
couches integer;
begin
select into pnr create_ticket(train_no1,dates,coach_type,no_pass);
if coach_type LIKE 'AC' then
	select into couches train.ac_no from train
	where train.train_no=train_no1 and train.date=dates for update;
	select into seats_avail train.ac_avail from train
	where train.train_no=train_no1 and train.date=dates;
	seats_avail:=seats_avail+no_pass;
	loop
		exit when counter=no_pass; 
		coach_n:=concat('A', ((couches*18-seats_avail)/18)+1);
		berth:=((couches*18-seats_avail)%18)+1;
		insert into passenger(pnr_no,name,age,gender,coach_no,seat_no)
		VALUES(pnr,(name[counter+1])::varchar(20),(age[counter+1])::integer,(gender[counter+1])::varchar(2),coach_n,berth);
		seats_avail:=seats_avail-1;
		counter:=counter+1;
	end loop;
end if;
if coach_type LIKE 'SL' then 
	select into couches train.sl_no from train
	where train.train_no=train_no1 and train.date=dates for update;
	select into seats_avail train.sl_avail from train
	where train.train_no=train_no1 and train.date=dates;
	seats_avail:=seats_avail+no_pass;
	loop
		exit when counter=no_pass; 	
		coach_n:=concat('S', ((couches*24-seats_avail)/24)+1);
		berth:=((couches*24-seats_avail)%24)+1;
		insert into passenger(pnr_no,name,age,gender,coach_no,seat_no)
		VALUES(pnr,(name[counter+1])::varchar(20),(age[counter+1])::integer,(gender[counter+1])::varchar(2),coach_n,berth);
		seats_avail:=seats_avail-1;
		counter:=counter+1;
	end loop;
end if;
	return pnr;
	end;
	$$ LANGUAGE plpgsql;
	

create or replace function group_ticket(pnr_p uuid)
returns table(pnr uuid, train_no integer, date date, pass_name varchar(20), age integer, gender varchar(2), coach varchar(3), seat integer, berth_type varchar(2)) as $$
declare 
type varchar(2);
begin
select into type ticket.couch_type from ticket where ticket.pnr_no=pnr_p;
if type LIKE 'AC' then
	return query
	select ticket.pnr_no, ticket.train_no, ticket.date, passenger.name, passenger.age, passenger.gender, passenger.coach_no, passenger.seat_no,ac_berth.berth_type
	from ticket, passenger, ac_berth
	where ticket.pnr_no=pnr_p and passenger.pnr_no= ticket.pnr_no and ac_berth.berth_no=passenger.seat_no;
end if;
if type LIKE 'SL' then
	return query
	select ticket.pnr_no, ticket.train_no, ticket.date, passenger.name, passenger.age, passenger.gender, passenger.coach_no, passenger.seat_no,sl_berth.berth_type
	from ticket, passenger, sl_berth
	where ticket.pnr_no=pnr_p and passenger.pnr_no= ticket.pnr_no and sl_berth.berth_no=passenger.seat_no;
end if;
end;
$$ LANGUAGE plpgsql;

create or replace function release_train(train_n integer,dat date,ac_n integer,sl_n integer,ac_aval integer,sl_aval integer)
returns int as $$
begin
	insert into train(train_no,date,ac_no,sl_no,ac_avail,sl_avail)VALUES(train_n,dat,ac_n,sl_n,ac_aval,sl_aval);
	return 1;
	end;
	$$LANGUAGE plpgsql;

set session characteristics as transaction isolation level repeatable read;