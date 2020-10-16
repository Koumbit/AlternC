ALTER TABLE sub_domaines MODIFY COLUMN valeur VARCHAR(1024);
alter table sub_domaines drop index compte;
alter table sub_domaines add UNIQUE (compte,domaine,sub,type,valeur,web_action);

