-- DROP FUNÇÕES
DO $$ 
DECLARE 
    r RECORD;
BEGIN 
    FOR r IN (SELECT proname, oidvectortypes(proargtypes) AS args
              FROM pg_proc 
              WHERE pronamespace = 'public'::regnamespace) 
    LOOP 
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
    END LOOP; 
END $$;
