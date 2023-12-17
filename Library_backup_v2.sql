PGDMP         7                {            DUMP_dz_Library_v2.0    14.2    14.2 S    V           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            W           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            X           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            Y           1262    49763    DUMP_dz_Library_v2.0    DATABASE     z   CREATE DATABASE "DUMP_dz_Library_v2.0" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'English_United States.1252';
 &   DROP DATABASE "DUMP_dz_Library_v2.0";
                postgres    false            �            1255    49888    borrowbook(integer, integer) 	   PROCEDURE     �  CREATE PROCEDURE public.borrowbook(IN copy_id integer, IN user_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    Loan_date DATE := CURRENT_DATE;
    Return_date DATE := loan_date + INTERVAL '20 days';
    last_book_loan_id INT;
    book_loan_id INT;
BEGIN
    SELECT MAX(BookLoanID) INTO last_book_loan_id FROM BookLoans;
    book_loan_id := last_book_loan_id + 1;
    CASE
        WHEN NOT EXISTS (SELECT * FROM BookCopies WHERE CopyID = copy_id) THEN
            RAISE EXCEPTION 'Specified book does not exist';
        WHEN NOT EXISTS (SELECT * FROM Users WHERE UserID = user_id) THEN
            RAISE EXCEPTION 'Specified user does not exist';
        WHEN EXISTS (SELECT * FROM BookLoans WHERE CopyID = copy_id AND IsReturned = false) THEN
            RAISE EXCEPTION 'Book is already borrowed';
        WHEN (SELECT COUNT(*) FROM BookLoans WHERE UserID = user_id AND IsReturned = false) >= 3 THEN
            RAISE EXCEPTION 'User has already borrowed 3 books';
        ELSE
            INSERT INTO BookLoans (BookLoanID, loan_date, return_date, CopyID, UserID, IsExtendedLoan, IsReturned, CostOfFine)
            VALUES (book_loan_id, Loan_date, Return_date, copy_id, user_id, false, false, 0);
    END CASE;
END;
$$;
 J   DROP PROCEDURE public.borrowbook(IN copy_id integer, IN user_id integer);
       public          postgres    false            �            1255    49889 %   checkloanexpiryandupdatefine(integer) 	   PROCEDURE     �  CREATE PROCEDURE public.checkloanexpiryandupdatefine(IN book_loan_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    copy_id INT;
    ReturnDate DATE;
    CurrentDate DATE := CURRENT_DATE;
    genre VARCHAR(50);
    fine NUMERIC := 0;
    days INT;
BEGIN
    SELECT CopyID, return_date, Genre INTO copy_id, ReturnDate, genre FROM BookLoans WHERE BookLoanID = book_loan_id;

    IF ReturnDate >= CurrentDate THEN
        RETURN;
    END IF;

    days := CurrentDate - ReturnDate;

    FOR i IN 1..days LOOP
        IF EXTRACT(MONTH FROM ReturnDate + i) BETWEEN 6 AND 9 THEN --ljeto
            IF EXTRACT(DOW FROM ReturnDate + i) BETWEEN 1 AND 5 THEN 
                fine := fine + 0.3; --radni dani
            ELSE
                fine := fine + 0.2; --vikend
            END IF;
        ELSE -- ostatak godine
            IF genre = 'lektira' THEN
                fine := fine + 0.5;
            ELSE
                IF EXTRACT(DOW FROM ReturnDate + i) BETWEEN 1 AND 5 THEN
                    fine := fine + 0.4; -- radni dani
                ELSE
                    fine := fine + 0.2; -- vikend
                END IF;
            END IF;
        END IF;
    END LOOP;

    UPDATE BookLoans SET CostOfFine = fine WHERE BookLoanID = book_loan_id;
END;
$$;
 M   DROP PROCEDURE public.checkloanexpiryandupdatefine(IN book_loan_id integer);
       public          postgres    false            �            1255    49891    extendloan(integer) 	   PROCEDURE     �  CREATE PROCEDURE public.extendloan(IN book_loan_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    return_date DATE;
    current_date DATE := CURRENT_DATE;
BEGIN
    SELECT ReturnDate INTO return_date FROM BookLoans WHERE BookLoanID = book_loan_id;

    IF return_date < current_date THEN
        RAISE EXCEPTION 'Loan has expired';
    END IF;

    UPDATE BookLoans SET ReturnDate = return_date + INTERVAL '40 days', IsExtendedLoan = true WHERE BookLoanID = book_loan_id;
END;
$$;
 ;   DROP PROCEDURE public.extendloan(IN book_loan_id integer);
       public          postgres    false            �            1255    49890    updateeachbookloan()    FUNCTION     �   CREATE FUNCTION public.updateeachbookloan() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE 
   t_row BookLoans%rowtype;
BEGIN
 FOR t_row in (SELECT * FROM BookLoans) LOOP
 	CALL CheckLoanExpiryAndUpdateFine(t_row.BookLoanID);
 END LOOP;
END;
$$;
 +   DROP FUNCTION public.updateeachbookloan();
       public          postgres    false            �            1259    49804    authors    TABLE     �  CREATE TABLE public.authors (
    authorid integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL,
    dateofbirth date NOT NULL,
    isalive boolean NOT NULL,
    gender character varying(50),
    countryid integer,
    CONSTRAINT chk_gender CHECK (((gender)::text = ANY ((ARRAY['MUŠKO'::character varying, 'ŽENSKO'::character varying, 'OSTALO'::character varying])::text[])))
);
    DROP TABLE public.authors;
       public         heap    postgres    false            �            1259    49803    authors_authorid_seq    SEQUENCE     �   CREATE SEQUENCE public.authors_authorid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.authors_authorid_seq;
       public          postgres    false    218            Z           0    0    authors_authorid_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.authors_authorid_seq OWNED BY public.authors.authorid;
          public          postgres    false    217            �            1259    49824    bookauthors    TABLE       CREATE TABLE public.bookauthors (
    authortype character varying(50) NOT NULL,
    bookid integer NOT NULL,
    authorid integer NOT NULL,
    CONSTRAINT chk_authortype CHECK (((authortype)::text = ANY ((ARRAY['glavni'::character varying, 'sporedni'::character varying])::text[])))
);
    DROP TABLE public.bookauthors;
       public         heap    postgres    false            �            1259    49840 
   bookcopies    TABLE     k   CREATE TABLE public.bookcopies (
    copyid integer NOT NULL,
    bookid integer,
    libraryid integer
);
    DROP TABLE public.bookcopies;
       public         heap    postgres    false            �            1259    49839    bookcopies_copyid_seq    SEQUENCE     �   CREATE SEQUENCE public.bookcopies_copyid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.bookcopies_copyid_seq;
       public          postgres    false    223            [           0    0    bookcopies_copyid_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.bookcopies_copyid_seq OWNED BY public.bookcopies.copyid;
          public          postgres    false    222            �            1259    49872 	   bookloans    TABLE       CREATE TABLE public.bookloans (
    bookloanid integer NOT NULL,
    loan_date date NOT NULL,
    return_date date NOT NULL,
    copyid integer,
    userid integer,
    isextendedloan boolean NOT NULL,
    isreturned boolean NOT NULL,
    costoffine double precision
);
    DROP TABLE public.bookloans;
       public         heap    postgres    false            �            1259    49871    bookloans_bookloanid_seq    SEQUENCE     �   CREATE SEQUENCE public.bookloans_bookloanid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.bookloans_bookloanid_seq;
       public          postgres    false    227            \           0    0    bookloans_bookloanid_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.bookloans_bookloanid_seq OWNED BY public.bookloans.bookloanid;
          public          postgres    false    226            �            1259    49817    books    TABLE     �  CREATE TABLE public.books (
    bookid integer NOT NULL,
    title character varying(120) NOT NULL,
    genre character varying(50) NOT NULL,
    isbn character varying(50) NOT NULL,
    publishdate date NOT NULL,
    CONSTRAINT chk_genre CHECK (((genre)::text = ANY ((ARRAY['lektira'::character varying, 'umjetnička'::character varying, 'znanstvena'::character varying, 'biografija'::character varying, 'stručna'::character varying])::text[])))
);
    DROP TABLE public.books;
       public         heap    postgres    false            �            1259    49816    books_bookid_seq    SEQUENCE     �   CREATE SEQUENCE public.books_bookid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.books_bookid_seq;
       public          postgres    false    220            ]           0    0    books_bookid_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.books_bookid_seq OWNED BY public.books.bookid;
          public          postgres    false    219            �            1259    49797 	   countries    TABLE     �   CREATE TABLE public.countries (
    countryid integer NOT NULL,
    countryname character varying(50) NOT NULL,
    population integer NOT NULL,
    averagesalary integer NOT NULL
);
    DROP TABLE public.countries;
       public         heap    postgres    false            �            1259    49796    countries_countryid_seq    SEQUENCE     �   CREATE SEQUENCE public.countries_countryid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.countries_countryid_seq;
       public          postgres    false    216            ^           0    0    countries_countryid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.countries_countryid_seq OWNED BY public.countries.countryid;
          public          postgres    false    215            �            1259    49785 
   librarians    TABLE     �   CREATE TABLE public.librarians (
    librarianid integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL,
    libraryid integer
);
    DROP TABLE public.librarians;
       public         heap    postgres    false            �            1259    49784    librarians_librarianid_seq    SEQUENCE     �   CREATE SEQUENCE public.librarians_librarianid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.librarians_librarianid_seq;
       public          postgres    false    214            _           0    0    librarians_librarianid_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.librarians_librarianid_seq OWNED BY public.librarians.librarianid;
          public          postgres    false    213            �            1259    49765 	   libraries    TABLE     r   CREATE TABLE public.libraries (
    libraryid integer NOT NULL,
    libraryname character varying(50) NOT NULL
);
    DROP TABLE public.libraries;
       public         heap    postgres    false            �            1259    49764    libraries_libraryid_seq    SEQUENCE     �   CREATE SEQUENCE public.libraries_libraryid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.libraries_libraryid_seq;
       public          postgres    false    210            `           0    0    libraries_libraryid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.libraries_libraryid_seq OWNED BY public.libraries.libraryid;
          public          postgres    false    209            �            1259    49858    users    TABLE     �   CREATE TABLE public.users (
    userid integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL
);
    DROP TABLE public.users;
       public         heap    postgres    false            �            1259    49857    users_userid_seq    SEQUENCE     �   CREATE SEQUENCE public.users_userid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.users_userid_seq;
       public          postgres    false    225            a           0    0    users_userid_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.users_userid_seq OWNED BY public.users.userid;
          public          postgres    false    224            �            1259    49772    workinghours    TABLE     ,  CREATE TABLE public.workinghours (
    workinghoursid integer NOT NULL,
    dayofweek integer NOT NULL,
    opentime time without time zone NOT NULL,
    closetime time without time zone NOT NULL,
    libraryid integer,
    CONSTRAINT chk_dayofweek CHECK (((dayofweek >= 1) AND (dayofweek <= 7)))
);
     DROP TABLE public.workinghours;
       public         heap    postgres    false            �            1259    49771    workinghours_workinghoursid_seq    SEQUENCE     �   CREATE SEQUENCE public.workinghours_workinghoursid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.workinghours_workinghoursid_seq;
       public          postgres    false    212            b           0    0    workinghours_workinghoursid_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.workinghours_workinghoursid_seq OWNED BY public.workinghours.workinghoursid;
          public          postgres    false    211            �           2604    49807    authors authorid    DEFAULT     t   ALTER TABLE ONLY public.authors ALTER COLUMN authorid SET DEFAULT nextval('public.authors_authorid_seq'::regclass);
 ?   ALTER TABLE public.authors ALTER COLUMN authorid DROP DEFAULT;
       public          postgres    false    217    218    218            �           2604    49843    bookcopies copyid    DEFAULT     v   ALTER TABLE ONLY public.bookcopies ALTER COLUMN copyid SET DEFAULT nextval('public.bookcopies_copyid_seq'::regclass);
 @   ALTER TABLE public.bookcopies ALTER COLUMN copyid DROP DEFAULT;
       public          postgres    false    223    222    223            �           2604    49875    bookloans bookloanid    DEFAULT     |   ALTER TABLE ONLY public.bookloans ALTER COLUMN bookloanid SET DEFAULT nextval('public.bookloans_bookloanid_seq'::regclass);
 C   ALTER TABLE public.bookloans ALTER COLUMN bookloanid DROP DEFAULT;
       public          postgres    false    226    227    227            �           2604    49820    books bookid    DEFAULT     l   ALTER TABLE ONLY public.books ALTER COLUMN bookid SET DEFAULT nextval('public.books_bookid_seq'::regclass);
 ;   ALTER TABLE public.books ALTER COLUMN bookid DROP DEFAULT;
       public          postgres    false    220    219    220            �           2604    49800    countries countryid    DEFAULT     z   ALTER TABLE ONLY public.countries ALTER COLUMN countryid SET DEFAULT nextval('public.countries_countryid_seq'::regclass);
 B   ALTER TABLE public.countries ALTER COLUMN countryid DROP DEFAULT;
       public          postgres    false    216    215    216            �           2604    49788    librarians librarianid    DEFAULT     �   ALTER TABLE ONLY public.librarians ALTER COLUMN librarianid SET DEFAULT nextval('public.librarians_librarianid_seq'::regclass);
 E   ALTER TABLE public.librarians ALTER COLUMN librarianid DROP DEFAULT;
       public          postgres    false    213    214    214            �           2604    49768    libraries libraryid    DEFAULT     z   ALTER TABLE ONLY public.libraries ALTER COLUMN libraryid SET DEFAULT nextval('public.libraries_libraryid_seq'::regclass);
 B   ALTER TABLE public.libraries ALTER COLUMN libraryid DROP DEFAULT;
       public          postgres    false    210    209    210            �           2604    49861    users userid    DEFAULT     l   ALTER TABLE ONLY public.users ALTER COLUMN userid SET DEFAULT nextval('public.users_userid_seq'::regclass);
 ;   ALTER TABLE public.users ALTER COLUMN userid DROP DEFAULT;
       public          postgres    false    225    224    225            �           2604    49775    workinghours workinghoursid    DEFAULT     �   ALTER TABLE ONLY public.workinghours ALTER COLUMN workinghoursid SET DEFAULT nextval('public.workinghours_workinghoursid_seq'::regclass);
 J   ALTER TABLE public.workinghours ALTER COLUMN workinghoursid DROP DEFAULT;
       public          postgres    false    211    212    212            J          0    49804    authors 
   TABLE DATA           i   COPY public.authors (authorid, firstname, lastname, dateofbirth, isalive, gender, countryid) FROM stdin;
    public          postgres    false    218   Uo       M          0    49824    bookauthors 
   TABLE DATA           C   COPY public.bookauthors (authortype, bookid, authorid) FROM stdin;
    public          postgres    false    221   ��       O          0    49840 
   bookcopies 
   TABLE DATA           ?   COPY public.bookcopies (copyid, bookid, libraryid) FROM stdin;
    public          postgres    false    223   h�       S          0    49872 	   bookloans 
   TABLE DATA              COPY public.bookloans (bookloanid, loan_date, return_date, copyid, userid, isextendedloan, isreturned, costoffine) FROM stdin;
    public          postgres    false    227   L�       L          0    49817    books 
   TABLE DATA           H   COPY public.books (bookid, title, genre, isbn, publishdate) FROM stdin;
    public          postgres    false    220   �      H          0    49797 	   countries 
   TABLE DATA           V   COPY public.countries (countryid, countryname, population, averagesalary) FROM stdin;
    public          postgres    false    216   H�      F          0    49785 
   librarians 
   TABLE DATA           Q   COPY public.librarians (librarianid, firstname, lastname, libraryid) FROM stdin;
    public          postgres    false    214   o�      B          0    49765 	   libraries 
   TABLE DATA           ;   COPY public.libraries (libraryid, libraryname) FROM stdin;
    public          postgres    false    210   /�      Q          0    49858    users 
   TABLE DATA           <   COPY public.users (userid, firstname, lastname) FROM stdin;
    public          postgres    false    225   ��      D          0    49772    workinghours 
   TABLE DATA           a   COPY public.workinghours (workinghoursid, dayofweek, opentime, closetime, libraryid) FROM stdin;
    public          postgres    false    212   ��      c           0    0    authors_authorid_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.authors_authorid_seq', 1, false);
          public          postgres    false    217            d           0    0    bookcopies_copyid_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.bookcopies_copyid_seq', 1, false);
          public          postgres    false    222            e           0    0    bookloans_bookloanid_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.bookloans_bookloanid_seq', 15, true);
          public          postgres    false    226            f           0    0    books_bookid_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.books_bookid_seq', 1, false);
          public          postgres    false    219            g           0    0    countries_countryid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.countries_countryid_seq', 1, false);
          public          postgres    false    215            h           0    0    librarians_librarianid_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.librarians_librarianid_seq', 1, false);
          public          postgres    false    213            i           0    0    libraries_libraryid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.libraries_libraryid_seq', 1, false);
          public          postgres    false    209            j           0    0    users_userid_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.users_userid_seq', 1, false);
          public          postgres    false    224            k           0    0    workinghours_workinghoursid_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.workinghours_workinghoursid_seq', 1, false);
          public          postgres    false    211            �           2606    49809    authors authors_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (authorid);
 >   ALTER TABLE ONLY public.authors DROP CONSTRAINT authors_pkey;
       public            postgres    false    218            �           2606    49828    bookauthors bookauthors_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.bookauthors
    ADD CONSTRAINT bookauthors_pkey PRIMARY KEY (bookid, authorid);
 F   ALTER TABLE ONLY public.bookauthors DROP CONSTRAINT bookauthors_pkey;
       public            postgres    false    221    221            �           2606    49845    bookcopies bookcopies_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.bookcopies
    ADD CONSTRAINT bookcopies_pkey PRIMARY KEY (copyid);
 D   ALTER TABLE ONLY public.bookcopies DROP CONSTRAINT bookcopies_pkey;
       public            postgres    false    223            �           2606    49877    bookloans bookloans_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.bookloans
    ADD CONSTRAINT bookloans_pkey PRIMARY KEY (bookloanid);
 B   ALTER TABLE ONLY public.bookloans DROP CONSTRAINT bookloans_pkey;
       public            postgres    false    227            �           2606    49822    books books_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (bookid);
 :   ALTER TABLE ONLY public.books DROP CONSTRAINT books_pkey;
       public            postgres    false    220            �           2606    49802    countries countries_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (countryid);
 B   ALTER TABLE ONLY public.countries DROP CONSTRAINT countries_pkey;
       public            postgres    false    216            �           2606    49790    librarians librarians_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.librarians
    ADD CONSTRAINT librarians_pkey PRIMARY KEY (librarianid);
 D   ALTER TABLE ONLY public.librarians DROP CONSTRAINT librarians_pkey;
       public            postgres    false    214            �           2606    49770    libraries libraries_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.libraries
    ADD CONSTRAINT libraries_pkey PRIMARY KEY (libraryid);
 B   ALTER TABLE ONLY public.libraries DROP CONSTRAINT libraries_pkey;
       public            postgres    false    210            �           2606    49863    users users_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    225            �           2606    49777    workinghours workinghours_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.workinghours
    ADD CONSTRAINT workinghours_pkey PRIMARY KEY (workinghoursid);
 H   ALTER TABLE ONLY public.workinghours DROP CONSTRAINT workinghours_pkey;
       public            postgres    false    212            �           2606    49810    authors authors_countryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_countryid_fkey FOREIGN KEY (countryid) REFERENCES public.countries(countryid);
 H   ALTER TABLE ONLY public.authors DROP CONSTRAINT authors_countryid_fkey;
       public          postgres    false    218    216    3232            �           2606    49834 %   bookauthors bookauthors_authorid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookauthors
    ADD CONSTRAINT bookauthors_authorid_fkey FOREIGN KEY (authorid) REFERENCES public.authors(authorid);
 O   ALTER TABLE ONLY public.bookauthors DROP CONSTRAINT bookauthors_authorid_fkey;
       public          postgres    false    3234    218    221            �           2606    49829 #   bookauthors bookauthors_bookid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookauthors
    ADD CONSTRAINT bookauthors_bookid_fkey FOREIGN KEY (bookid) REFERENCES public.books(bookid);
 M   ALTER TABLE ONLY public.bookauthors DROP CONSTRAINT bookauthors_bookid_fkey;
       public          postgres    false    221    220    3236            �           2606    49846 !   bookcopies bookcopies_bookid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookcopies
    ADD CONSTRAINT bookcopies_bookid_fkey FOREIGN KEY (bookid) REFERENCES public.books(bookid);
 K   ALTER TABLE ONLY public.bookcopies DROP CONSTRAINT bookcopies_bookid_fkey;
       public          postgres    false    220    3236    223            �           2606    49851 $   bookcopies bookcopies_libraryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookcopies
    ADD CONSTRAINT bookcopies_libraryid_fkey FOREIGN KEY (libraryid) REFERENCES public.libraries(libraryid);
 N   ALTER TABLE ONLY public.bookcopies DROP CONSTRAINT bookcopies_libraryid_fkey;
       public          postgres    false    210    3226    223            �           2606    49878    bookloans bookloans_copyid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookloans
    ADD CONSTRAINT bookloans_copyid_fkey FOREIGN KEY (copyid) REFERENCES public.bookcopies(copyid);
 I   ALTER TABLE ONLY public.bookloans DROP CONSTRAINT bookloans_copyid_fkey;
       public          postgres    false    3240    223    227            �           2606    49883    bookloans bookloans_userid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookloans
    ADD CONSTRAINT bookloans_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(userid);
 I   ALTER TABLE ONLY public.bookloans DROP CONSTRAINT bookloans_userid_fkey;
       public          postgres    false    3242    227    225            �           2606    49791 $   librarians librarians_libraryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.librarians
    ADD CONSTRAINT librarians_libraryid_fkey FOREIGN KEY (libraryid) REFERENCES public.libraries(libraryid);
 N   ALTER TABLE ONLY public.librarians DROP CONSTRAINT librarians_libraryid_fkey;
       public          postgres    false    214    210    3226            �           2606    49778 (   workinghours workinghours_libraryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.workinghours
    ADD CONSTRAINT workinghours_libraryid_fkey FOREIGN KEY (libraryid) REFERENCES public.libraries(libraryid);
 R   ALTER TABLE ONLY public.workinghours DROP CONSTRAINT workinghours_libraryid_fkey;
       public          postgres    false    210    212    3226            J      x�m}�v�H����������XJ�L�C��MeWN��M��H4A@$���f~d�����= F���>]�!������G|����}��/�ATe��a�{X����#���*�2ݶ�����7m�EI�{X��!�����o߃(ɯ��S���!��_�5ו\%κ��J�?���m<��U��bi��Gs���Ȩ�ʂ;�u��Ynj������o�iv�?��i��*�����{|��I讍�"�o��[?�����Q�{����?�W~:�*��qy>����{,+�ߣ����ӦeErUO}���yX���J�a�U�9M�����f�9�w+nOa������X��WQ|k����j��Lʒ�F���X����O��צ�x�'�v��z���q�G������4�64���n��=�=?:�0�ϙ;�S��gs����~��6Vr
��5)�1�ؚ�g��#�JV��G<A�0.���;s���7m��䑱��eu��y��f_w+\��F^?E�.��s�||�7�~0�����G�(��s�r����Op7��=�Z����yd^�u>b#M�_c�?4w��Lw�Z��W��3t��_��z8���?�'�KhX|3�?��-������;���c8�8� i*rK?�B65���9���O<4���j٩/[���O���<x2|֧���2T�mi�^A���a���R��.y�|��3�k����oW�c�0S,��p�&?Ɨ��^�rT�>r�>��+(�WX��fǳ,b~�w�Uv�z���? ��B�r����	��Z���ȕ��~�Z�$P��x�'�;+��H|�nd�^%ip׌������{�}	��>���,x:�a1��fhVk�-R��Ԋ'�#Ƀf���7�"sT�H��r�c=@0��kD� �����IJ*�p��v+~G,�Uu�9�J*(�j����Jo�2�h#�JW�UB�j�0-^�]���8����Wi|�y7ЈM/�2���7N"��mSL�_��D*���U�U�P�7��/�����][�_��渄/k^`��*�|O�G�xj&�k5��0����Q��S��*�)�C�]�7�&���m)�,-���&x��rc(U�4{��*-�klx�~���+�xR�O�x�JM��w[�cw��*�{� �X�Hc1¡�Eu�E8�uMU�C��̟��{����u'�`�Us8س���#�C&��E8���,�Q��L�E���:�J�<	]g��e�t&8��8�{�#�Gv�K�D���7��]k��1W����?_�=�0@�]Ӊ�Oe���+�湆�i^�J�F�d�L�����q�x��#���4d�U�䎯�8��r�ќR��#8�<��h_!��q�jƿ�'���?`e|��7���z�+�<�_�	E���x)>s�/��Iy�������?߀e%�0�F�Φ�ʳ�z1�]|h�k�ʪ����.4�	�ؠq-�z/W�*�jЃ��
o�.4T:猕e���n��bP�����ŭҫF:����r��@z9� ��U�(�o[��[f�|�{�Q]8���[�Wo��~�Օh�١�WE\7��}7���/M;	�T$����;�e��o�T�Awŭ�U3#, �|���j���tNf5�*��+*1��EN4��A��9����w��;�����إ�U��򳑈O��(ůBoz��O��~;lTy�kI8�hYT�_�}���w8��;a9y��[�@0hx�[[����!��J�����	Q�;���D��cK���h`����C߯%�T��=N��9�\
@��o��E*�'��*SXA�-���0���q�8�(�^�Gk,�5�>AZ����٩� n��%xX~���HD5=;�Z� !>࿬G+$�śE�]���\�GMENgH�������̀��� +'����4e�U
~�����Y$���,��Ȇ5�Iw0�n�76B�2 ��b����z��ĒDՄ��$�g7��?ǗVO���A�(��f	�Yޚ�m�IG����UF�04�:U5�z�Gɯ*ڸ����߈�f��c��T�{V������"���e�M�C�N	����>�óF�ť��
껯i��a��a�D��\&N�`�u�ǶnuǓ�
�I8�KɃ9Ҏ�V�s_���� [�C��/h��VLm�z��8���B3��(��􂳡@	��w~���D�-��-��~��PG��9��q'$�����_]LU�P�d�#�,�Ѱ34���޼��~��KX� � �M���H���8�T��������%��K� K���=�qp��4[��X��$&��h�ܨ.��z�8�懘������-�G�q(�]���l���h^�Q�7�MP8�2
}2 �Z�u�霣8;�*t
���1�w����	N����j�rkK�r"�3U� �_����bSL��\��3qN�1<Dm��iB(,���b�N�꺆�������ba�3�X	���D����	���X��O���~��ß����@H6c�.��ђy�&�$P{y�;Dp O�`H����1���'�k8�߀J��:�Z�������� Dx8Z��M�J�����,�ݍ͊�����X��$  _Zɵe����3�¿ 6�����X�H$�����\��O?,�k$����T9�)��}��p^|2 'C�r��1P\�(��{X��;��A�ΔP�.6*�%��x߬��wpM Mp��oƁ��m���!M�� 1E&�i�W5����"�\�ve
MM��[�q�lI-�*W|��*��(�y�����@(b}k�.�G�C�I5�����~ڑ1_�,C[��	�+���ʟ��!_z�4+���ߛF�T��hM�`;JCI��n�jac}��X����V��:~
`z��R�L� �n0�ӣ�T* ���2K���0b'5$	m4˓O����1��@�>g�s=ΓbsmƔ�IG�鷁�8w�&_������~د�[kR���Ԙ��"�mx��Mu��{P2�i|�`��_s[� cWUSZ�Z��=�=�X2-�K��f �\��~%�C��'ϲ��9+<G�R]D���e1���A�V�E�@W�#ld⍹�������R��xf�8Kmn�������2�+�J�*���$f�C�]�e���D�C΀����ɡY�@7k��E>��i ����F��~#;�A'���z���J|s�y_�Z!PG\�T(˷M��S�#X���i��p�TܵT�������aW��(6se4� ��O�OX�*}�;)>1���g�$O�u�KV���u�#�����#DQ��p��|��u%߶Tl2�,��9������o���ڞj�at�VD�};�!��(*��nA(�bF����=���)D��rW�	��f�@����<����%�0�|D�<�s�Ee�;�2TD�?���Ң��i�Lcx?��#.��;Pږk��B�T�Љ�oD6E��v��"��%�+��`���E
�iu��urpκ�����UZ+�6{��T�A��E�;��e v��`�B������E��7�~
NWl�L�]���m�˵�X��~�����l®�R�
��D��n!:�)��Z`q:�oZF����Gm�����70<�2~�m�6஝J�B��W��f���R��J�T�b���'�a7khd�V3��ށLв2#�\6����B M��2��(�gfg�_�fo�˦�7��r~jNYh�l������R�)���rs���%b����PCg�r�#�(�U��<vf���+q3ye3�����U"��ø{�P4Sb���ciLx��ێݶ��&�-Y��=����Z��sm���Α�Ď6����~I9��6k�B���A$���=��֏{Q�Jѻ�=Hq�U||g���c6#�B0�t"�1V��֙7fgS�Y�a^U�,�aDO,hIQ��H޶�-x���B)�����a�4ݖV�7��    O)g�
���F�3?�o��G�����
�>�}�j�HE!R!��m�u81<�o����+J[Dt�&+��2Avv����E%s5�qZ;�,��uЮ	��6�C=�Ҵ@}"I|�%Z�ik���*8;��ArIC�C��M3X����U�u����	~�F\�d����,G�ڒ���~��P	���i⬀Z~�صP:ǣ�)��Kqe��Bxhϛ����gfX�X~f��^Li�8�5P�jä�n��q�և�&�Y+��w`��J
��0�t���a�b��'����z��nQ�y�SV?�'�ʦ��j�˅n�E�m�v�����\��r?�?_1��(-f) /f�|��+X8��C�C������_��1q�x�?�6-��
�D^�}�aЏ����4�����V���?�}A����#	6~��P����B_5���f �52���yƈ��JP� O������sn��^@�f��r�Q%@�:�Ҙ�"�?(.-���=��
f�c{�S���`�76ݙk7���������ގo��re,����������	{����������@���J�Vg&�fS�L��|\"�۞�CC%xi����cIBV�1/����d��O�.�0�	&�в����;���w�Y���������a���pIARׂ��(�T�K�Y�k�u�5)�h�q�ia&?�m����8��q�r������^Ht�)��K���i�ȏUq9 �`)�H|��6 �����_�4�O�՘�Ku*�<�)�M���Ât�����|4�)�%妡}���-/��ƙ�vY߄�H� If {:\��.�������B>�`��%ݪ��̛��ٳ�/[2�S��R�VSyQ5�7qZA��5�Tq��/�Ӵ��&�+�r"Rl	|+ITƹ�2����Ț�zx5S8u�x�e8�a�1��?vJR���N����2,Y'8 ��C��2?���jD_B� �}����E�������KaD�xx�Qt�"�1e��,'�A��ӛ��^쎝B
�,��ň������w����Ƶ���d"�U�?̻�_&�4v	�'��9�4Mٖ�E�Ux�<��A���$�ېM�nzK�SNzҺ�Agƕ��4�g|Zcw83���5���Ј3�Q��P��z�:�>� �Ԗ��ˠu)�{6Y��Ql!�����C��*��1X�����Ba�pf6�=KU��0�!���`�~Iж˾���K
�NJk0`G��g�a����ZV�b:ˬ�|��0!�pᎠ��,�d6�*n��Q����AW���`�H�fU6vf,mc�v#���$���~jJ�a�+W�`�k��I�8B��9����]1B�W���	�T�̅K���By�L�ް�e}A�W)h�B�e���������9=+�`u�5�-9+�4���8uf3j�6B�(4���_�2�pE���n[�JE~=W���-^��q���Sr����v��v~y\%
Q�R/~gV .��,�-�E��eb��Nl�e�ְ;	�W6��k��Y	�K�����9ٔ��O���A�a;H�m�m0�P]^���%�0C1\0/W�G%~S/�2��hV���ޙWK�zf����9mO& ����r��JY���k��@Δj\,���5&���}i�?�[Q�+kr}_\�,芬�m�ֈ�N�KxH ��$�! �&���PȬի���G%>�J�qV�pV*�SQ��˄�TP13YF2��)q����7!�������V�S��=�K?U*��0����臙��giUd��>B�^�^Y�6���!@����T덲9s���l~x�$�DDH��(^k�_� Z�.�Αb��3��.rs���5k� p��g

��R*Q�fE"�8�g��y�7�ڙx76{����0�9���Ywu���{*Y���lG��Lˏ-�{�k� �E2y��dd����Eּi��G�|��)IG����Z��-��A�\_ِFZcޭ�<�	2�H��?�� �V��U�(�LT�b-	���EcT:US��S��(�d�·�!!ф!i�؀(�
��f��SP��w�|O����͒�\]��̰�E�϶l�����'�&�ȏ�4W����ų{��>����(a_��ҏ��M�%�(��wĜ�-� �.wG) 0�J��V�^��E��r��	6䏚��'���U^��D����C�[�6��ꅭ��}p%	��G"���(e�P�g?'&�?�땴<4eg�lC̪C^��,,)(����`w�˃�V���J`��G�\*�����P������*�]����~�
/Ӌ��rI,AׁD�ߞƁ�񼴜�~�`%+�-BY2�7��`�ؓ�"�䍨+IBɂ«~�'����,��^��֯�,���~òx����u!��sS57�bT.S�
��W�B���
|k��]p���`ʷ���xYp7I��F�?O/K-�5���2�!		;s����F}m�@���S�)I
ֱ6��Ѧ4t$�7v�$�VRB���ߴܕY��@��O�X-�Y��Ѭ֊�c�y0�`�K|jY�^�~Qf�����I�����{j���M �%I�/���7F�cO]a�Z�9̃`�0�����d�UR��)	A�FzL�j��Jk�įK%i��_V��	zjg4�4S��I)[n�n�ωC�K�P�h��5=��m�(�O쯸��vf%��ǡ�����xr���B��������v5�j�}��&%���7R?ŕW�f�דL#A�����#�
9/ R�Aрy����P�[lp�W�|��f���(�S>�.![�o� ݳ5vIh�����Jݤ>*��/|��Kd�y �ݛ�n{�G�#�=D�d�\8�=��7}k^T��8�qa�ؐ%vCa|��V�}$-�b�U���u����V�܈{bjbi�����Y�R��,k�I�5Q�k�`����Lk.F[��eR>��1�q���.v�^mQ�H�Or�N���ӛ���5�t[D���jͷzb5۬��E\�[Gw���z"��^7k�`�s��W�|��^븕%��>D$/��5�����سMad��u3|��f��PQ���#���=,�lժ�l��)c���0��k���dހ��|J�/��1|��ҫ�줚A�d'"%E��7��p��m����7�r5�I^���V;9o∹Q�j��q�#aZ%��,��<�B���]X��Y��TD�Lk���DJ�`��eT����#�
���<>�lMʋ9�\^�3��F|�e!��e�C2j��b_и����x���jR� �=�5�:쬝��^T�͕҉Ő�6����
�1�%¿���O��>��N�x44HA���ą�dM��vh�xV������l��_�۩�?��;|bN�w侎�Q�U�v�&��������`+�Qb#�C*P�<P�ޏ���zm�t} VI�.�9��Æ.A'��q81��"ʠ�\����}�[�If6zr`WŞ'r�)W�.WiT �>=݋���d�jɚ۴�uz�ǥB�a)hF�n��v,q�U6�6����|��Zgg_ ��]�������n0F3��I�%��B�JO55�~�aIU���0�'���K��9c	d�+6�����\%zH�ϯ&d�U�I���_�v}&��?�!O�8������U˦�N�z�2��軚&`�7J�O�Z�m�$5�!��^Hpw�C%�׆c��$�[������^Od��;�8��Lhu\�e�M�D���@�P|�p�����Z�97!�٥p��������rr���()��9]5�B���D�w�gV��|��e��8�m�$�n쮡�l�"� V��!��|n�U��hJ�3�_��V���gԴ�x����/�i�q���փX��7� �K0���K8�k�Lm��)%	���l��7�R����F��_����9�� F��ٝ�֞�O��G���.�u����@��{�5'H`D����    �jʯ�����Lz�m��@�N�S>`D�֑͢��8#����o� )@S���;��o��!swx�g�F ��U'e�w�T�[��D��
��l}���>�M�OVLZ|���8���w�\�M��r�x���E33TS���yH�=��,�]^lp�����N�qa}��);�;+�񐉐B����9�z�e��5ש_\O9���c�SRi뉊�z\D)l�'v����y���V�]<�M�$��

7Qz��0aϸ��r�E�F�?2N����"�h�_��4;�r)O9�\V�G0Mҩ��v�))��ߦ��s�5��q��x�]p��T�K	uk6��MS�~��K�!\OKX�%��#:lם��b>��#T`�nkiS|/�@K�*x:���l�P_�K��aJ�H�%赆�V���5��iiv/M?<(}Vpmlad��հ8ΜdQ^T_=St1��,�$�za��͛�'��c��k��wKɢ��@&D�f�6rf�T-�Τ h-娋F���r����Ӝ�U�ɜ��$���\:�6eɟӘ>��X��Sw�r_%'o��$�|[W^���5v%�A�4�� ԭ,�� Z��žC~N�\����������U"=^ꁿ���%���FIN6����-���y'��d���g�0o�f���]gs���1��.�a�r-�|"mr��2N�Az�.�
J����9.�<Nf�2?�������Fl�F�B���u0� s��{`$���(�sD	�s���6�J��ɧ�T;B����E��{���?z6�d���L7D0���a�xU���w�|?),���C�$���d[?�7���l�f�윢+�c�2�J��
�k�Nf�������ec���!Hz{Gȑ�,n�{I��۹��{��Rp�L|mtl�V"~���5������+s*�����z�k������*E�n�4-B��eM���F�Qy���E$,q&e�y#=����g?,�����ۦ�3K��X,�`d�Y<�'PYTK��EB{}h�c�	.!Ĳ�H����	��O�x8-rQȾ��)��V/�<�b{�z�pÁ�T�w/]}���ү�W|~��+�b����ë���Y�٘�~�p!��T��r�����Xs&{އCߎ��ʳ�-$��)��BvZk�I.,��1&%W���8��0�����4�n�"YB|aD	]�;#S���ΚhM�S�r�u��߲��>ܔN��3���j�b�;D��C��y��+�4 ܞF]�e�:\��x�y#7ug޵]�~�M-Kfh��.��W,��c;1Ғ%�V�[�mp�.!x�_�p�FZ�P�F
�˭�q�ͶrV�����a' �ө�g#>����f"�[pͥ��ʲW*��Yޓ���&���͵i�/����h��&�}-=[�q<���Z�����l<�8!�D����Fp��������;D�� VK��8�Pg�m�ܬ�fVFp�l:��[^�"����Ǒ�Ɔ���rò��M)b�8(p���흜@����"ż���Y�UĊ���CCJk�ʠ)6	>�ȩu斅���=�KS���Aj�B���=�gS��=_2v��e0vjSig��9�W#�,��4y �#%y��F:gnzNʓʇ�&<[�`m	�+�3�꼔E�&t?Þ}ж�O@�}gg���Hz`ه�΍y�_y�I����~/{ծ����S9.�4�	�?�1:E&�$��xYH���ә30��^0�[ܤnhq�tK��v�@f'@�)�,"#���c;��S�g��pο��w;�A��ݴ�S'iH/�p�kyQ<q������p�x_ب�2��NJdՌ6X?��c�����7 �w�������^�]#�^�ݐ;@�[��O]KR��[S�s�e2�c����?h4M�#c�����z120���TS/ma�h���y��/���鹯��<��y1�i/p�ǑC�N�0/���c/�0�����ԕQ��N����}�Ԩ�J[J.X��YL��+/P�m�� 3��x��t����v�i3i2G�s�
#i��dK���Gf���cF����Q�X���s�6X�vI8��ڇ����.g�\LR�w����[�]J�wǐq�_���4h�B��>I�ٴ���3�E M���������
2�4j��}���2��)7��s�v\7�F]s��S��1%@���f;�8����)���E��y*ʋ��"�<���o�q%�֕D�a�n���(�M�=[��4D«`q�b�H�d�#k���*�:���3N�`P�G@۴���9�9'k�܌�D��zl$6�������Ld�2�u���Wvگ���_0�`.d���ϒ������cw�UmNs���2��,e{�8�%��5���2��F���jf�I�>�!L�fۿ6��mseq��=W� �Y,�-1 ߇]=HB1զ����35�F�OK`���f����<�,�]t�Ock'����p��C�2eo�li86�M�g=k��Y�CnWG��q���p�d�,SV���΢�gpF~+ŋ�5pN�rRk�_k��;���J�2�^�tj/�����ܪ,q���̜�tTDt>�A�E�}}[k;�� ����s�k7�/lֶ)���s��f�':��-�~ۃ-<r�>5�wc���п(0I�L@'`�l���>������^�7*ρ���� �g��/�>S��-���T��3���奶�<������ފci�
����øS�y6��^I�8w�[W�� 6j��3� 'YdE$�������ehi璘�A�1��{�=%��eMbhTA~<��O�ގ�$E�Q+�zʜ-����@���bB�Nj}�'*MRZ"��ŕ�-�"�{ie��<��o ���YK��Uk/�V�|�?�$/r|��W�t1�֧�8����B0���H�4
���±�2���d�	������J�E:H6s��<�҆�~�aV�v��4K0�
�C��s	KO��7�2�u �Y�����V��q������NQ
���БȈ��b�4��a��s��B�3���/�JS�%Wv�}�\&� �e)=5ߺ��2ytX�?�NFW =�Ck���u`2�C����_}_��jLϋ��|��U��g������I�e��/؜��U� u6d���.�?�u���qa��YS�}e!��ǱӚ�VV]-a=>�$uKF���Q���P��Y8�!�8���	{%R�|�/y|hT�>+w P���� �/���E#�VGuu�y�6�s]%3#�
`���Y7��<:'��n�����D%9^�fٷ��\���Ql�f�c?r�#��;��D�\��S�K�ޓ�FҺ��l`������_M���[j���9?�����J��®�9[�$P�Pp��x�?n�^){y<G���ayU������U3:>5��%�R���W��N�������v����˧��O��:�#�L6:����k��%�<�t���(RTX#�Yj��<)�Iޔ9����F�ef莽vW�fw�B����$��U�N���y!֦��y6��?�����h{z��3V��k ���F-�9�sWr�9Ǚ��|O���✷J�ϡ7,-jM���O���E9>W2�LdȘ,�x���V�v+	g~gO��M���o��a`gâ�rポ*�J$_G�{prcy2W
�f�����"�pЌ��(���
�#�='���B�7��E�<N�f��C�^�a�m���	�f��6��tv E|�%;�������	8�t�Hr��ri|1������_C�#�#0�mݴ�5V���iِZ�*yd ��!����?@s����~��^�kv(���'�M"r��-{;'�{�l�u��Bf���z�|6 �Mqy�H/ζ���f�̌
�Y�&'r�'��	d�?��<� ����N�wR�"��D�ht:���9�����29�_h��~�zΔ����g���O�q��	&z�� y�@ur2wf�8��	Pʙ��UQ��7-��YMN�:稌~��.nj�9b%f��4�$�%9����5���g;�'¥�X}oӮ�k<MLS�|����~�$e$���^�    ���4����*���f���+Os���:GZD��F��a���\%H��2E��XZ�tr���B:�4>KQ�2&�e�CȨ�=>J�}r?*;�&�
=B{����5�F��r���#aY�!�7Ȁ�%�u�?�#��M�D�]�'�PS��=E�`[�-���u=��@Tk|��P����d)[��Ni�_{x������@2���8l�W3ɍ�B{���/�䷭6��|��)�å�B%aL9�r�/t�#2�A�H��<�<��Z�����Nj��`����h� [�<�O��}ܿ@�@_΋���Y�������uvgR��7��1��ckg�XE?�P���<	���e��̓H����Ls�Β�[Jw*�\���P��^���\��s~}��T/�/���׆�V_B�Y
�� -n�������+N�����R�֚�/�/�kҙ^��	�b��̊%̇�+��a�H�Bs�9>T���ι f.�C����z��E,TW��i*����:BɊD�)�zZ�8��C�����0+�����I����
�܏�L�|�XʥO�+��\�~�N���B�S*ʙ90�7���u�2l�2�D�<1s�6�������Jl3��7='C�I�X���n�[ˍrѕs�F���2d*�;�kH��W��G3E�-X{d+��"��M���kI�" [5'#�G,�D��#O�g�a�$&�����8�L��,c�җ����+_C�o�E>DAdzh`l;�ݿ���</�������8�|Zb�c�q�����68MN��E�+�U���_��o�iH��Ζ�
��L��>.��B�0�78<,�B��"B�)53蒁5X%�[�����d���;x�*f�1�x�m��A5ú*�c�WH��r<U{�����Vi����j�멫<�涨S�֨b᱖TΣN�N-g��8l'�t:���.)�rN=�ad���X��@�N�>�j��[�2Z�1���)Zy~�<�@�Jr��Ӑ��l�%΢%��ac&��yx���^��D�`��V�g�̵�4��C�۩1����E����w�kͪ	��7f;�W��k �yD�u���N�rM4��R�����슦*���Us�l�<�Q��6>�26oI��7����=b�+eg����[�I���=�]�l]%d�P�ɓ:a��J�,�Y2�����B�J�{\�U�џTgfI%ÓF��v�_�Ĺ����o��m	T�G���.�<�;�<�@'`�~?㲔M'�A�RY���O�c�(���7}��t�4A�9�'����{0*ҷfG�W�n�s�Ml�-�5�v�
#<<(��y��R�S�����qdΓ`e���#Tj��"�:�c�zϐ��e��(�_�����CGj��-L/��COn�Lɀ�������`�[Vĉ���L=1�o�g��S Vv� ^u�)�4�=��
���{E�,��ӵ���(�G6L�j�J7�eg=��KG"oW�>Vw��k�Xܭ�&>��R���&]�fp؈�ƅ6v�5,�ک�jb�r�0�oL�;{��~!�m�s��\<]�`+���yA2/.� ��4����w� _Cf��л�p�d�8�f%I�/�Y�$3r��T�����c92�ay�B�娷�><?�P�?�ŭQ~hN=�*��ʉ��H
.rZop�+�D�sJe�g��.<���N��	^
����/�:*�����^iC��u��t*;��7N*҈yM���ڞX���W𥤛Iރ�O���٣ϖ=X�	oFh�\ToL+YҸ��l��Ԏ"�����g/q������F�zI����"��\��U���X�7zO\\�P(|)��x!-��Bz1ϒ�e��,�Aq�셷ei��s\O��{�^^8�G���d��/G����BGh۫��;�(2�s�ᚪ"Z��������,�{�����D���9�'Q���T�i�[���)��r�܄���8v�-����V"���/�AA�C/���M��w���d2��i�kk�5�n���N�y��oK%<+�ڭ/�ۖ�n��$�t��.���}܆��P�a�ֶ]��-�����v��G撔@p>"��װyd뇈B�+��ɸ��²����{���r�Tʅ��N�5�2<�X8#MC�rQ��6ʟԓ`nJ�B[|6o0�V�'�o՝�$1)�V��=���i,�Ȏu;�l�!L��z{��}d����KB�@��v�?���r�ֻEYM�ք\]�W륡�lE-VZ5��u3�Y�z�;3v�U�8�McQ,@}fJ����e��7�"|�C=�s�ۧ�U�E��a�]�����#�<�ev�ʅ7���\�i�a�Ι{�B���H����x;�����.�ύ�$�t�jw��$����t��79�44y��U�t<��*�O�d޼�x&'{
	��W?쨀�6��_FX���>�}g�W�JSOm�7�J��}�Mr��W~>��ffn�?�U�����р���k�/O�v�9���J�%yB1�����<�*�Y<c��~��BS�L�+ȳ��ڭ�mj[�	3Kfu����6�i�t�t��W�� nD%����(�)�}F|e(Yq��(l&B-�ϊ��vR�*��֎S�TMWI��:W���j���u�LXμ��:C�$x�3e�ց��4��8�a�QO�dJ�|i[h	^oRQ��[R%Od��|����U饝��$��~u{�-�Ǖ��ɖ�A� �2�����g�S�@��M4��q���I؍K���2���3K��&	�$`0��s0�S�g��Ԉ��B�A
���z5��Px�z��2�m�¯y�o9]䄾V�JXD�	����2�+L���m�G�q������]g7'�8�;�c��س~�u��X���Ϸ��@˩���C�q8��Ƌ�8B	�s�׳�I}\����e��q��Wg|U4��XS�@(�F~7��c0�E��a0`%/ZH{�:�=�2j�%�zb�&�t�k4�frKM%��S-3oF�m��lԫ��x'{���&�t4�$L�ΐqu�A��Q9���\�R̫�3^[tGX�5=e�Wb�e�B9����9z�����ɮ�FQ�Ty��Uܮ�<^��;x��]�<\>F篒��ʐ�b�k�-\��Th[/���uOd�����eÁ@;�d;��N֚�c^Q�+�_N,��kc�|	�l����tGK�/F�՗�eO�7}dȔ��x�{�r�>�Y��D�W�����k��_:^}yݍ�����I?�c�ᤉ��-�Tֽ�<K,C]`��
W��]?͛(*;��6Ubç���McK�Iu��I[��J�]
n���0%� aΫ�#�lv��ͫ�K�s�9�e"�[���v��ұ�e�hF�������j2�vxT���N4����Ug�<H�!��I��k�~I⾵��{V��$���f����њ���P�.\�mY)fn�S�-V�W���^kSS97��51���!V{�iR�Ҙ8�����4�b�n1�"-mN��V����p<F��P$�m��C������#-�	/�c�}�F����7�i��ȸ4��ԯ��Sk���{"�+�y�Ī����t�*�<��c�R��ɜz�z9��MQ�f�՗���oJy/�ވg{o|����ͬ0�����]�����e�}�n���NP��IG�0�-��Ϯ�Yˢ�S[�͛�eڨ\]Q���,�2���2%���/��v^5�M����}�������1�La'���4���6�UY�޽�BM~@�����%:�?��]f2���'O/D���b�.J6&+dFM�l��3:�ѸkS8��^�ii�Yb�c���eV��)�cA�U}A[��<e�z-���`�1Ͽ�g�˸&��<)nf�<mr�+�l��ޥ����YmѪ��a"Z����I��jj7V��]���B=�|oc�qj�rj�)���;��9>�ԙ�@y�y��b+^��m7''t��A
f����?��jS[�?CpX^
��9��<�L��|GHeͧ��>`���jH�}�Y�i�<ີY(�K0�	���d�����h{)��6��y��4!��� 	  5�ѹ�,�,鐺;��UU����ϧ��z$o&p������L<3f�W�}�rЖ�2��"�,rf.j�7����0�v��ѫ�aʤӍ��Osfb�d� �����`��]�QB�)
�Ƕ�P�O�H���0�Ep�g.α�l���%(�hf��r��$��|<�:�[���p1z��jW��b�/Y&����F=���u7�M*S�f��k$uGg>k���0����cG�!=��M�͇�>�9�p�=�Z3�Dd����E�:��.%�6q��qql%��L7%T�-? ΰ�y�Ӕ	�{�w�aWy�j���e:{��v�x��e%�v^�9��i.�[����#'�}�C?5+�^6��.1]a�0<`�
8|�	fR���(��0��}�(�ּ�f�x��IUY��`�+r.���	��r�k�[�+�x�S�z�M�iU0H����f�͕�§'8{�)�J�T���^�d*蚨'��/�	�φW��N[���@/)0]��Ur,��/���Gɫ^u���X������z;��������f%�]^�;Gi^�6�
ٸ���8���q�2>@��G�k��������4��6�~[^ciN�̔!���-��T7�̰����(����TV�f��N�`4���^�_g���qE��-���*��G�n����,�P�(�Ю��w�h/Sޞ#R<������mG�,^�4�6����U�����3�6�{R|=��k/���Z�_8��ݑ�\�q�GvZ�&��]��̰S�'�(�c[�%G�,[$uaYNT�o������\g�Ǘ{T�<'�3 ���P���}J��5K�w�E	�kG�"tm���!7��Ԗ��G�|se=lH-��T3�۶����n�#V�dZ'ߛTE4�m�p�R���,7L�[3U���J��N�|��R2_�4���Z �1Dg�����6'Ἒ�,fbI�/0�i?:�cnT1�� ����W�(�8?�u�����r�����F��r� /��b쐇��0�����5x@�$���o:���ί�!����k5��jq�L����rm��)���N�����bs:��a��a��S-J�3B�Y%�2�ĸ��&����7I���줇.�*���d]fi������X�Q�#���ys�v��Ce�|Vv�g�:I�3u�)��ih]���F1k�ì��|o�wba%�2$��X�jT�|*�S�xUF�v�zT!�U�//}�y���kS;��4j�!�V�̹���X������g��_�]_��f_�|w�N��{I+f�������ﵖZ���O����'1i�ۭ��%�Ћ����b�"�?�\;"\��f�[��4�����X�y��4P׷SL�O��ʊa�^��O�!���!��,�j+�W����9��m,���p�-��v<�?��4�7-�����h��gI��J�U�����iJ�����T;��go���Ax=傇,�\�јF�J��gMҦez�-ꇃN]/���kF����p�����f��.��E���{-����=8� �þ�e��B�3^���tځ��z�#a���:zQ�m-r�Ax���݌W����"�k�s�b���?[&B�]��9��<땦�4�Ӄϕp.j��MP����y��<��\��ͧF�8����$�'�g���HF����;�V'��Y�/�<����-�����-;F�?���ĳ!���*�ףU��� A(y	/�8�o'YLϮ��.M�̹�o
N4{�w�"4�
��3-�!|ηuL����蚃4��ӥ�H�7�$���pg'hhh��f]�
�
dqTJ���3�m�����V��0Z�Q|�Qt�Ev"!|��l,翜��JX���[T���$����WQ�2<rl�5��<�O�H��	e��8L/nA��C��t#n�}/	��B]��^q ��0w��q��GU%�T���w��l��౧��n�<,M/���S�:�(Zk��d3�4V8=���Y�C�����<����36��G($���E�N7^�����F�p�އzpVzF%.*-疽�P�η��ɟ<��k�:M����g�{������~������4�f0:7��N�
E�_WM*�i�ɝ�?�}#�az^9�q��%�o�e����P���\b����r����9M�u���;�fz����[���:y�e�d��A�@r��A.��s�Z��i����,-GZ�h\)$J. iD�X����q-yCA�x���1yJ]��I!�Uš�fˋ��1e�Mo���k�$����J6P�3)4'����uuu��6�B�      M      x�]�۪6;W���u1��'�≠� *���[O��UY0�A:��������������ۿ���v���׿������_�3(��ڟA-ϯ3���_���E��7���y~��`���^8k��?ss�_yb�y~�d��+5��֯4�j����I^[�f�ǋ�����?o����G��ϯ>U�<vz��~Z�m�ݦ�f�i�T�����5iZ�9X��$�Q�f�5S5�"�Gb�X�گ}l:[��M��x|����-�%&�Ipm����G�Y��?b���h�!�.!�`��z�c������������%�����G�n�7̠��o�i4U�m|<*b��(CA��:���z�E:��	�ÉsHm�G�)�7?j��7mc���G�h���{��Nݒ�Wj���e�3�����ʳ�����U,uYG���߲�ɮ�G��'W�f��:Gf�<�޵����
�C.��%y~~;Z�ic����h�m&I��UZ�����-1h0���G(b�77���ѣs���\�DCP7��B���>����E{=�b(?��yRo�X�9�ǚ�#����c>�+���|���cV;C�U�W��4��-Ê�C��On�}׾�L�k��&Kz����ѵ�p��I�r��:eI۫"�ۆ�Y҉�Ί�<�^[�q��wS��eM�SvQ�>�Mn'>�Nb/^�;�%]2AH<�x�����!�~� ��]�G��~m�k���v�C���'��ƟP�#Τk�Sݾb��v]�^��J���M
��ms��Ǹ
��ّۣ��"#X7i�xt�>~��v�!��/��~~a(v�c1�!`���çf�����B���,o�	1}�Pw[g
��㟂�b�?��A������h�V2�h��Q�P XU� }G��5Ӵ4N@#WZ+�l$x#���ʎ���4;|��N4X��M j�3�z#�@M1߈Ј1	���AፓO����">;W�B��8�b!0�Ќ�)����LDN}�����|5:4�F�г���0�Z�K��Y
��S��0}0�Bz
�h����jx��U5<L	�<p����@��j���ꏰ��:k��	���o��X����� �7<,�Տ�C")w�������ȫ���4���| �ar�Û]$:�	]����nt�$���椛�����ЀY��qm�cU#CLՈ���ע�G^����r�BGj�V'2�G��Ϧ��jy�ٻ�r$#b�������P�H ��qa�;_Y�P�:X(�qa�R�iZmN�#k�P>/��nE> ̩ӱ.���г�kf�������jDX�wG��&d�� �I���#�7�ӂ9	x3�恕�L|��M��T���u�$a�^3lC����&;��^�D�B�<i����`����4J�L;2���˫���j������.7��lZ�@e��V)f3����6B��0�<�{�8�Ԗ0�$��,a+�i�g�a@^�E��Hb�K��x��Ax��aF��3����hb3Mx7��9(�d�+lN�☑`V�6PYM3��'�oC��`�I�ʦw�&49�f��Z�z3��n�i-�w��}Mnr6��x���re��
�[�[aY3��+�N��3je��4`3��G��-K+Q Q���W�*�P��ud�����b�l$=.Mc�����$� �ȁa m�!�bLK�W�$� �Ma�@����z�D��Ө���W��]Yo�a@�J��Nr�������mG�J�'P	l�"oGՊ��i̚o؏3��:���vx[޵,52
��0�D��Ӂ��5Tr%J�۹�w\�p�ץd�hK�zB�'�BR/l��:����t���a$R|,$�ũn(�R0�D"��WF@
�Ї�)�M�d�2y�^m>�6�y�	��Ǟ@�s�%�~��0�(Q`�U,Z�p:�o�|A�7�2��64y��MF��U��+�R�n,�jz�+J�z�XnKx:[�����n< �$ƴR^7��и��� �g7 ��{��h�3����|�q��;� �P
#���9��`L�N���JDwV ������#�&��"�`@
��g�h�z���a��$�y�Q���	�K�1	�%�1�j:�����Z�kyV���^A����FoL8��oe�\j��Oؘ���%v#�Ʒ%"l�aȏ�,��	
X�1��a��������lxob7q�CQ�n\x=FfJ�� ��NV��pYA�Lw�p���,Qz�W����=�å"�d��h$.���DE\#s��[�Lڃ�W�e��1a1L���V¹�L����f�V=p�7i�_Y}�E��p��0��#s��~��|��&0���:ef�,G�
X�\1V};���2��|�������hk&��D��N�ifF3X�k���ѢvŻWcC�J8 B�!02i��MaYԈ��i�:�֣����t�G���q���R���y� �
h�c���qy����H��<��0�.,4޶����MQ;�3�y�l1Q!�(3�� (W �2�q�=����kF�������Q�e6��J}ӱ�>U"N#�`�uEmR(���v��Rx<�����t�G�j��W���\b� ��� �`�;��/ɴǆ1a�g;�>�^)��.��8�Q�V]�4�D���Ε]�7'"޿���?.?$"���\a��\�D�0�s�����L����fBt�O
�dM���Ӹ�ݒi\��|��jq	�(Z��kg�jm,������G��*B�),��݌��x9���^%].oD
�Q�2�Y��6)��L��5C����ey�il@m����`h�Lc�+�vuH����D�g�LIh�6$4,�Oӥ�s��bX �\������k�&K�����64l���*�vf�B����ZL�
9g���s9I�
�g��"��r"�M�d���N�����b df�)���&t�i�T23M�
�����3*G��gΐc^�1(�_r������H �ˉ
��u��}!������m(�B��N�6��V�$���s���<܄roƸ��jj�-⚖!�F�t�P0��!0FP1Ǽ]ć�ތ���ִ�d�J��t�P�9����� vO����R�LD�|��^1�E�X����yj�xW!�2,.v]`�p-�V�i�eP��v������i=�����g���I�����^���Y�B
�����N]�"B�\��g�~��W����%�s��dA�lE?���ၥ�t8�S����\�y���j+�&�eʭ�ă�y� �z�Mf6j�l�4qɅ#.��p��gH.ʍ]�u"h�~UܸuhK��Xy��V��n��D��u�#<p)U!ƺR�����(��������#E�+�ʲ�e\�JF�q��seKy�Ǎ������!�@��)B�X6\����޸��#E+/ѐ^�R-���b��S�e��߮}�u�3��R�bE$���� ڸ�d�f�����2���2/dʠg�Wf:em�Yu�!�`��ʷ���96�����إ|^/ͅ�i��a�Ū����ȵ���N��#ʺ�D�A#;���>�Ŀ��P�6�s'4HH��`W}H���f3%���a�l�x�J��p��n+.�G;8� ��X.|c4�Jꤧ� ����Vꓖͤ��Q����G��Z���Q��fڼx`�lC�r��� ٧�?<��eI~��ܼvP��u��o@䵷1��Ծ0���%TF��
�vԏ����#n�lCU��#֯*H�]z��vԐ
�;M8|̎M��q!�p�c�YA"��n�lBSr��u1K�4$t~"��P/�}�<j|��->fH���NH���WվRC3 idL@,����#Sx�|��ngC��dG��t�(;�\�r��5����^WE��Ha$���{'T��	����ѫ Q<\ꍯa�LP"���~���G��oŏ֤;qǘ;p N$h�y�}G�ݾ���>����ߎ[�ë�Ѹ�a7�o"� ���4{�ht��DV �  �'2���݇��
�jx]�f������Q��G����5��	0x��f ���K�+<y߈z�ĻS����3�󍫩���n[̋��C�y¬�F��y��%��z%1�۽)*95���R��0�W�EK�ys�����+�Ɖ<�D�3�J;���(���̓�e��cP����N�x{�m��x7s����=ޢ-��=��'�My�s�&�_�D�����B��9`F��ԑiv��wd�ǰ��"1�ޝ�6>~��7P8�34�� �v��<�+���Y.��� ��*(�;	
��ھR,�kG�Q�#��S�������D� t�h&�23x�e@�s]>}DNک�~�@5��ц;�_!����gY7�Fp����]x���S���˸��m:��\n=��#~7�O��0�H.N�?�y��O������]      O      x�5�ɕ,7�Mc�;���C���K��*.@"���:K���WK��z~�����(�w��볬���[6����W�r}�_=�~�qί�R���_��6�\����ܓK|�~�T���Ww�뷿��837FNϞ�_c�S��[l����o^����9߯������<����&\����l���s�NΫ_i�ǩW���w�-�蔎�d���ZH )V��-�#��d
�����K�{^������}Q��_eT��4���,R���l�����1���*�M���؜���QA�A�Sx��n_e"�����EA�#ө�9�=�Q��K�ͅL��峩p�T*K�Ot0���
Q��s$"<$bG�!��5~�-!pd��D�I��ڿ��x�Ԁ��Y�a{�!����k���~���
�늢p�}��ݬ�mՍ�7��K`ıA
r?�L����LC���~Q��:j��s#U�(k9���@l6׿� %�qJ��b�V�QE���.���G��� ��L�]�����K�qn��T �I0��?;������fcu��Q�c'�C�|��8a	(�*��7��U-����vU�e@�F\����U+�J����XŸ�3�
J�/a���=s��&,*޾XQ�R�r� ��yF��	0�3Ш�{.�����fsȱ�1V�p�Fe(�&����^��¸�s�P؇$H:����{���$���>���+L2}�bX������Y0�˾�^eO�hP�|$���r��Uf�,���������W���,�W�G݌X����,��r+�[����ŗ��Ё+���"|���#���ÈXL�ÃL"2H�<D
	��sc��u����m��#������9��n\,X��;T$tд�Lt����[QD ��)%��_T��cV� ��f���#}��8���*J �[H�b���p�����^r�x�L�0����U ��dHvA�f��|�3����W@�$�h���cp.p��þ�U����l��sn ��c�.��B^������຅. S��Pt��&���X��		���9Ā$#N����-~�uD���C�c300`����5�b��ZՄ��j���V�����8�*
��mU���[�w^!�>mf*�&>sm�ە0@(�m�i��7�2�����4b��/�2\��wM����3���/�,m�(�>�i��AC�|�0s�o~�+.f�*2=ڏC���A�� @���> or�6b]�/#V��/ ��B�vpWx��m%�h������DE	��GS�@�J����g���i9T�cl1��i2���fD� �`|��,��Q<����o�#�ז>l���6-��s!��n�7���T�V�;�c�b@IH����G� p��(����w�b#Z��"��u5�
a��/
��Hf�.&V�
�,J�9b]P@����xB7�G�ط�@@���K��ژ���/��&Dk�ozh_%���
�����9�֐����xNY�2P�T�3C�N�ql�,D��>/�7�y3(�3AZ�-T,��h�+��.q�����MZئ���b�㞢��9�@�pk��n�p�u�t�!�;�zB�˨��^	������	��ࢫ�.W�����&�M\�ҍ,0*	�`��:d���l�9��\7�hbD�{O0��	�L��
2:�אA����w��25�%�Љ����n��h)�ı�8;!I�{� �qd��d��2yA�g��t����b>Ȥ�Fx��D*	/�|�XK7���>M#C}}갎�/jD(M`w�b���<�֗m�]�JF£cK��]�H �P.Z�X��]M�������Ɍ�(?�~s�"_|�Ž�=S*�,ⷡ`�!�3��u���
��=��a�y�B ~��%�����}ѵ��#$�jl��L� ��$�bH�xucKj$�`��� �"6|
,�tl��LU�`�I�X[=��z@~5�/L`xa�Bv*g� �g%�d��򫘐N�0ԡ���̕}��d�����!Q�L��9��A�I
"~��2��k+fJ��}q$������$꒘���5e�/y�^jz�bvjb�Ѿ@��[Md�>����0���
���M�oP�8u$L1�`�1}Cz��|oh����a��a�:��a2bR�ӑ���:�I=Ÿ�ie��
ʐ-��|�c�Ovc9������4Q��;I�0�jɬ=��ɔ�_-�6��\�a>2"{$'gh�P����d�$ؘ�ݰ?W��rԆ%	a��lg�O�f$�SJ&\R�od:�8��RM`2����P��L
���m�����F�8%W�J��n�������/c�&��/%��[)1�E&�Q"�蛭Z�x)�H�bD&䆻Ìd����k��a�W@�D`�.��~���7σ�I�H�3�LaL�����bRR�juǀ�3�qM�=�#3�T X��4Lp{�i�sǍ�MJ^�ʜd���1��9	�Mct����������M��ԗ����FbC�3���*]�t�����x�I�2EŎ��T0��Y-���)e�xP��G�I�{�S�JA�e$����L/�X)�Y�0�w�/n�m��$۝M�$N8c����^�U}��7��j�JDg1��4d6�:���CZ�3�	���홾\l5���_͈S�I^zC���'ǚ	c�M�"�G&�G���b��KH�`A�9]��ob3I4e��9Q��0��z��;��i���	��~*��_:��P��Α"�_�$'�\��x:k����'�0e`�n��L�b&M�
�A�	�c�iB����S{b��S7��0�xKX㦔0�Ψ ��#�i�ǈ.�+-;z�&ae	�D�cƖ&���Q
	5�#Oq>�ԑf�K��~����v�=�BVD5��eR�w�USK���ql����X�[5�!�*ʮ=�IO��g�r*�+�w����8?%klK�0�`d�Le^�ab^�����[�eY�|yڲ����� �c��v_�K;��<J�w'4�#��j�.�87Um\V�����bx�_n��bX76�|m�?.+n�������o�p�t_ᤜ=/�֪8�4Z����$@�"�گ���zUt�7��b
�[j_+QF"��^E�I��,V�T�q�N�k�z�28�յ�'�>_���J%3Y��A�U����#�k)��WY�"W8c�%0��a����-���Ū�u��$���R�|��Zi ��)/6w��.9��ެ?�.Tu�!0��t�]�Փ\bY�P��N�%G��.䎷�����9`J-:Ԙ�ǲ^��Ba���$�����&�z�.�������1����i�����k���3����H=%��SsO���r$W�w4�OK�m�_G%K�@Է�N#��Rv��wYð�G�2+V���1?F��K�B{���=\��g������#)��fJr�کҪ��a��H���=��*�N�3鑥�m�y��������x0Q�3D���W��A��P�d:�\�ڳ�']޵��b�ʬ$����!a��z	�ՑQ,���١��z��<93��(fF(����iS9>ĲZ�~�����NN8�lqkz1����,,�@-J�Z�ԫ����m�b��HZ[,�*����!y]�mQ~�^����Uӄ8�mR2R��{m=Ѥ;��� Lg7�Gz8��c���!i(� ���*��y�T�����m��=eY��o_hJߖw��S@S�)���ϙ�~O���F�ai�`���on)y' ��e�IYޜ�l`�cR�c+.��I·eϚzC���P:/���t8=�� �	����C��i�(���nsФ���� Ƈ;��)����«ҘV4����/�IZ�>/�L��>�6nI#�,���>v.�e��o���.5i��Y��cny�	�k� �;ҟ�v�%��j���j�V1����H��<-�Ú�����F I[ɪ�>r-`1���[�uM���i%���^� �  ��1b��P.��=�c�S� �4�_)�b��28U&d���2�%�pJ��ƭ)�
N6����x�㵉Uۣԭ#3'��`���������1�8)��]WX�!�ŇSy3���%B&�X�I�w��2�gzaA�[W�����Ө~���TX_������b��4�.	�R|-����x��|�'�	�{�S~�rQ���̴�45[Xػ�+����{-&�7ե3�l��Ǭd'�=�EO�L��O�А#�ҝ�|c�Ц��.�*�.,_o�Xpx>O�gv���ݖU�W�:FEbL��WOj�*C<�K��_b*5��ŗ�0y��y��	��8�XG�����=�f$�ނ}�W�.��_Y�ĳ�ڭk4L�$�-6�_*�}cy�k����\{{�H����WGت|��t<�J)O*2�R���'S�p�-m.w�R��4�V�����Z��tUX�D#�4K]��ͧ�Z��_E�!���s��d�W1�HQ����r�U����eZ�כ)�i��$�����K���f�C�"�t(Vb��H{�&K�x�=���;��Mjz�U��w�O�Ȏ�y7�l���h����J����$�ׄdŬ����Rnw�t�S���r������a]�v��8���%�Z~�R�6���%0,�v_����L��3��oE$���RG<�n����D�06���ȋ"җ����Wi�!� �y7M�՛�7�/B����RV1����rr������_d��֧"��w �`�M��5>_�fI��2ߝ8һ+	'|u�j"P��6��X��KVb�[f?ج۩n<��T��RO���ђ�Sl@3i�v���|��m��(m���w����&:K)�e\��^�~���Y���=L%I��E��
�͝��Y�(3²T��V�ؕ�l%w6�K�ǋUҺ�H�;�E��ֹ4Us���ߢ���b���V�(�Tc'o����`��J)�a4�       S      x�u]I�$�n\G�%�q�u����3L��z��oO:��` �(�VZ�-��-�����[�g���|������Ӫ��r��zn�ϬU��G�������?�o��˻�&�c�?k�c�?��c�?�����|l����|l�c�巌��-�g�uɾ5�G��O�����[���h�b�f��{��(������,W��%��u>�����}.���6>��O����ɃSۖ�e��v>W�ط~˼W�\&�׏F�h���������l}��ĈPt����_Ӗ|��])���Xc=�u���R�6>�Z'~�{P�FV.{9�±�1ns����B+���|��}����?���c&�����_�����?ե�ڎ󟐙#�<C���i?��O���~��:�g���i���?uئ�_�ˊ5��ըV��6�iګ�����u��:'�:��&�Pe���y���_.����o�'h􌟗-;W�[Oh\�ӱ�Vt��|��Ֆ���5�����t�����G�����V��?w;x���Y��f5���6��ܰ�Fl�r�5��بZ��s~�i���l|���A� �x�ݞFyj�����A�_�Z��˟�ӆ}�2%�T|�l�l]�y*���L!�M^�e�*(��JQh)��@���kU�:E�ڶwV|�Qu9����ۼ�)?�kک��ϒO�ئ��yP.G�y�h9ҭj|֑��f������<b���W��W]),�-�Ȉ���Htov�P��]����R�;���n�\v�|���X�{�v�DK{
G�Å�;?SO�VH~�ai[�e19�Z9��\&D��d�H�Br�|��/R!�;ͻ;��^��u>���'N���@~'??�l|��w���KL��h!n��SБ.f�6�|1;�gT��GE4�hoٗ[����pe��m�1����kjt�8y�?�^�J�XN�^äYV�~ƈ'�,4��b���tX�1SF��d��T��Y���::�Z�A�Q��-�$���a����� &�N��]͖r�do�Vm� 	xd���S9R�~w��J"�~�x������,t���M/A���h�Q�Uܵ��L�ڇ|�tmǹ����tp����'2Ui�E���
��n�<�Q}��C��i>㇙�>MO�W�,��I5�]�Ɍ/���Wd�``_i�/����ZT�*���U�K����T����m���U���Y�g^��NI�`>C��7��t��]Ա��B�%��h5�C��Ga��T�5��ceS>k�P����مCׯ$K]=6������-j(ƀ�]Lh�ͳ��e�&}k+��˃�c��������Z�++]�<���T����?˴J͓�tA�������E�����~�B������;[��(���|��A�����`s��'<Z� vC���(��|���uMY�<�L��<����cY�;�z�>MU����Z��ΰ��en���|��bLS��gz?�I+)�{�����eQ�\�qU��V#��n�#�	�fsb�΢��Dt�M��T�
Bq���*�f���Q3��`����u��O��ZġA?b�;��.��yl�J9� ��R��l�[�.>pSF��sl	c�����p�hǆ櫑n{uL�K�$�YI���X�q��3s�)���U,�;��g��_�t���,ö����l/xl&Ų����'���پ���j('��9�C�Kl�<9'��b['y}}+��՗�J[��ϭaZ�uHwX�t��]�ȑ?Y��}� ����n��/�����!~��9���u�O����X����.�����z,f�D��r{~}�dP��ї�mb�����ύ��b���=�M����k��BK��so�2��J��a){]@l?k -�g����^&z���yM�|yE�3-�m|�֦nN��a9\H���~��J1,��$^�׍t�NtѼ�����7W��>5ߥ�-L�g|MX]��)�9���F��}3E��Ԓ��cQWA,Q�k��&��`�����Z������hhӲ���r#&h5�D�uK�6՞��T#m�_���,٫n 6�f���"�7�]��S���:��bz䥣SR>��Lg��G(�I�։�W\��"��D
-B]����}���
���W�mOU`b�Rx�LH��*U�M�;��m� Y~ޤ��g�|�IY���x��Dzn<Y�3�p��
�����z��P��[��Ʊ��e�
�h�֨KbYY@��D0-�"5e����^|�w���p*�&1�ݝ0�\��p��S��u���Д&^�����Y�!�������q����{�Ob��z�O5|b% I(��h����5wV7�t�%��-Z[����Bb��b�{5Ml|o�#����`Z��)�JD������*�� �W�n����O���&?f��'�+i�X�`����s ��>c�_Uma��T�-�*�
X���О���5Pc���yV�^�!�:m̨|��х��&B؆�L����=P�&�+�[|7X�QB�d�<%�Y
O&�u<�obo �E���̶�ČL�C�����I81>�)Æ)��Ƥ��}����v��A5`���u�v�'l�i��]�&�~�p�u�p�o��@ϯ)c��i.�c�D�D��a�ԃqb��p a�E��t���iQ�娎�5��V�q~�|"���Nȼ�%s�:�؁Mu����ȑ©����P �Em��-s2�*��Ȅ���1���}�>���Y0H�2fH˜����G
��hP���7� �����_�}���!LoM
�6�bk�Õ�b#8d9QI�TV�~��Xn�i@�%����q�8u�pjl�\���{W���F:Z�W����i�d�yY��F	��E��Z|���%� 0tsJ,�,S.��^�m?c�-I�ae���Ek�Հp��|��8l\ ��xO����,O���Y��c��tQ�����Ը�m��K����`3�%8"_?��X$��t���^ �#'�b�����%���F*�T�v3�n���oD����x��HL�fg�����#���kA?u��&���x]	�������3��c�r��L�*�8���V�v\����'N`�x���
Р�b����؁��?���̃1��xm��m�?!g�o�1�NV�"�e>��NS0\����J#/7�a�-���>�a��� re�$���mI�6�q�W7k��׎o7g>W� �����' ���'�`��!������U����Բ*S�z�m_�%^Vbӭ5�Vג��U^xՃQ	 Y�s�n�ᱯB`��!.t�2���93�+�/�yð���dq�υݸ���)�Bb�iW�!�Ή!P�g�?k��ؑ�'�H��ES�l�͚�ˡ�,k�(kVM8�ތ��-f*�����nP����o�g�.���d���!3-=���a׍��I$�L�61E�IU�	��`-`�
��f��&���;�f�y���A�b9��'�F$#fc4OQ�-�în������U�zQZD��p,豬�O����X}���Hl�=��X7����"kqJ�شL��^V��'c�YVp�Mj�%�i�U�fNgO�K�06]�sb5��,A���g�@���w�>�Z��ۃo�����ZqĠ>1�W*�����TS?�j���-G�ġ U�����Y��I �[�b�MN�'�����V��VV&hު㻖�[,#�O���D.Z���K#m�t�Z�q��O�����g����p���yXMd�-Ọ_e_���]_��Q�]Â���-u�.���<&Y�`eC��5�ح���{b��q�0��E�ZB6/�SY/��������x�߈��&����O<�Vc.�ޠ�F�E��$���,�V!`r�byO�Πg��a7��zI��[u)(�Z�'n�Hd�.�#*�Y��)�M=�]5�]ԭ݉��n
�1�E]t@��Z��u�Y���xYC�=������=���Ĉ���t�e�'TF�m*�w��&x���l�����g��z�́˱2��#\,���O�l�%�į ��b���P��TD&R]_:6�6D�/~�8�ܴ��4    �K�x��+p�E^G��-��6�ڲ�=#�6<Fl/�[3��lr��r<�
+�����-��~��մZ�u�2��|��Q^���h}CM�7q���'e��u���4���4��%�W��<�6�g�W�����1��(Q�k>�3���*��cµa��$��=��%kV觍�:Ƥg'.����|m&��5��m�]��Pd�mډY�՝�(��*���)1C�W��g�Yf57׻>&@,�8��%Lrל��)~�������$o���FΨ6_D� ��B+3o���Fr�%�E��B�\�vR�}�*�1�U�UQ]Z��f�N9c��T?�cd��qd+�i�fT#�ӑ٘,�W2^~5b�h>+�.�ZR�8�n����-ײ��R��ʊ���Y��~$��+2����S!׉�u��������P�	�q-�4Y�ԇ� <I����"����v�%��A�/Y&���YO����������fH"���if�N����a6�1���j2T�nlFǇe��3R~;��f(C�ٶ3j<�=���J^�
xm�	#�`��&t(2�s�J�`�`�k���d���|�9H}e�Sim�i���<�f�h�8I�+�D��ր�6�p����Jl�Q�ƨ c���&�մ̀lO��"p߭�L������b���Xj��@)���n���Q)a�'�ߞ��e�f�ҫ��|��<$����i檻�����P[*�� �84E��:�9��pj�����{��9y[pkl��u����jZ�1+#���Y�K,��Ջ�}�7F�p�壴a��źx��O��B���)�e�7��'ְI��dU�A�s=V��3��@{E���w�"�=�s�XI���v����~�Gy]�Gr�蝘z��?��r��;Y�M��:�����䱐qx+�H���xԚbQ(3u�͟0������|p�=a9=��A{�#l��J��a{��qg���}���i�M-ŝY�s`6r���U��@1z�9�Dw�ҷ�����|��Þ;��$������\i����� �Q�BJQ����f�U�(�=�
���%�|Z���[lV������!�ǣ=0���Ŗϯ��N9ذC;�w�`A�Z���BP�r���G���9�1	P��ļ�k%��@AS7}�S_�%����ǁ�^�����.�l=�6�z��tE0�Z}�R�M=x6*�O<C=
�u �{��:���<�3��B�{o���o|+S,@��c�`�m+L�6�=#(���S:�5l��.2�ԙSd����H80�md�?�%���ؕT�����&���Љ�Z�<���(����/KJ"���b�<O���G[AN�_�F����WOHA��h��j�"��_�r$��V�	<|�728�V��x�bM�ۨ��r���F��t���� u�ݺނ��0�����Pa�gb;21��9�1r,���R较)���fg�帺#�� �i���{�AD�'�ޛش4<��I$�k=H,��ڮ��eZ�������k�rb����:�9Y0� ��<!t�����'n�Q�\�KQ�F��`��t��<'i���� AuR����h=1P���,2^2P�39�q*C�k�J:�j�[=�b��d0�ob��0�ڂ���/�F��'�GI�Yק��o`��FcfP�^(�0�0��#�,3\�y[*z ��k�����A|�g2��.�apAf��A�ѩ����QaG���IܷK��Ҵ�c���Q��x?8x�/�|��=3��"ρ(�ʢ��S�����Aȉ0�H���Ό��`~Ù���V��y�[��&)szfد�8��4(���S���T[�9�#�hX`�Ls$�}=D�t^���+G5|��gs�J6��t]tJvk���V�T@�(1x�ۀ��.�<����:�	�
���Qױ�
H��~4��x�iD�-�ɝ{��9����逥���{Y����>d�X,�ҭIBc���,�B�T�� ѷi���C�l��)؞~����'!����~b���ʶ�R�(�t��j�X�v������Ock����/QueZ3��;E��V>:�4ֻ�fn[����_-���}�xoZ��&$�0Q�v<���(X�ᐭfq4{{Em�;��n��֕��ݚ"6�oKQ^�����j�u�h7��e-��DQ�[bD6�f��fl�u�_;��Ijv�������M�Ň�g{a!��?�_e�0���~��UK*�>�$��`�Fs���un�j�ע�,�<3��=SFr�6���CG�Eg���&���&T���|�ld��O���u�8Je)�X?�H���	S��R,&5gL[����O��U~۴�qdj�+��J�;޺Y����[�]�*��5s ���[}��~X�0.wc^{��QX�x��#�e:�x�~;������T 1��I��4��J+���2Ff��d�NI	���3"���Ў1sݠ&��k����hi�˕ac�l$Qy2�̱]��Yn��+�X�����G@�e�W�=2��5�>�����Pv�_4�<�2�4Se6te\�;��4^Our�Ѝ����Mw#!��1���ig��ܣz�M�)��p�m/��f��i�#�*�g�A�3�Ku�b	K�i��&6���YD8�e=p��x���^b�+1e�;I��X��VC];J��
�;���lX���|o��K��X�[#��W���6̟�Zl����5�΁�>�+�h฀���76�VI[k���"�h��H!C��\��y�+,'	������F�e66��E��,b 7�&�ݹܬ��X�TA��0�4?��\#�!��	���ܟ=x�� �����A���[�OX9{�Ρ	%��_���Q��k���q�������� �=��� ���ʍֳ+6��2���*�L����rV~?���1�`f��S=QF+��;�:}eL����~fF�pq�i&j��;��X��o��^Y�|0*C��&�.z.���I����ng���� -�Fc8U;[��m�M��Jm"��:ͣ��ڀ������L�H�[K'X��ɜə\CF틮�� c�F��yb߈�H��g]����GK
25߇J�;�*���n��|b��cx��NulZ�Z(�蓕�8�)�d�� ���J��r�	�R}:��~��r��2��
X�z�Ƭ�3���!�NYǰ)
�Rn�Ds��%o�k� A>�t4'�X��te�n:J�mT�5G��7pl�E3ɉϴ)9����b�׳�i��;-�l.1y�B���k���.v2��#��w֒�qc�i��c�*V.>`"[���5�3��W�ª��<�qf�Ƣ�YK[i(br²Z�w@Ѿ��u��5Kph���M�.��
����U"�D�N7���,c��
uyQ�k�I=$_���J���+_Fd���pE#�ucz}����xw��8N��v��Kn.�J�����ä*��x�ډ����H�?��;ȾԞtl�C��[a�-��O�����n1β��(����ҙn�;<iAv�J�ћ���8;#�4�;G4�̘�����X��������e�և�u�j�逓�T8Z��ވ�5��y�r(����z�_� ��*���=YmyEI#�:L;sr���������k)����Fدw�~�&��.�,�vxeRM3GM,�@`4�'=�Ӱ)KX�byO �0Fr\ӯc=���������RМ_J)�f2s'hd�8w��ƨ��s�2:��'��I��jt���m]�o���l�[�M�V���ʄv�6,_� �O�c'�Z;��3���2bV.6k3�#��G;��&���|0���`�y��v���(��
����� 3u��{���	�[4/�N���@��$4��5����:���� ��?ө��f��|��S�ţ��'���(�hw]�}��{�5 Z֍y[ю^�����ڣ��1^%���?����}���y&b�)�s�xa�    �,9��-��P%}ʧ�v�5O�ɇ�l0L{�b�Z˴����{�83�n�e������'f�"^y�N6�$x��jx2[YJbp�Бs�Qv�!�"��5��6���@�Ҍ������l�sk��;�L0���ək'}�r<V�0����Z��\	t��߯�I@��8>���U3V|`.Ġ�+���]H�V4ސ4R�ij�S�GfL3j!`�i �a	�i�ďuP��l����f���kR8�n�<9�Y�o?�p-�����lg3���l�OhWC�K��%	�;jo-c5j��˴7#��Bbim�����gD���4�A�g>�G9���;���۹�9��z���j#f��E�p>u�訡M���?����㫹��b��j �[�I�e��o���RۿF�@r8��[�� �2�䡥��@/~l��L+��������fc��^�c���ٜ�f�RDʳ{ͥ�~ٳk��:�C�5+�K2�M��V��	���Xrx�����82��c�8C�vq�šf9�������< `�'�{r�͞k�-�.Д9�U���U��#x�ϑi�I��Ľ�W{�
A�g�$F�h��!/3q�\�{L5V��9N��S����n\���[nRlњ�ݪ��gNg��W0�[l����Xy��b{�2%��M���ԍM��~E��6L���4��u���1�T�W0Rb�EU��0rzM'o(�Q[�-eR��Ϙ��Z��A&����8"�w4��z��9SP[&B�s�؏d�9ܽ�r�4�66d��`9�W3Ŧ�s���P�삹�z<P[Z+�,��'�=�m�,�W���z�(9��(�N�t�H�	��� ���w;ǜ�ce��c'��/��l?�����@d��~}�ô�L���2��:sT� *�J��g��gWR��/����vHc+v�?���E{ČA�g]�{Ex��Έ5�x� ���a���Q��[�lfM`�a�o5� ����2���i=�m�s;V���C\Nc4/�S˶'K3�oS�7� (��{�uz�YQ�36Mguh��|��q��`/�`].!ۊ�Qޘ�B�4"��0��ѭ�fc�v�^�d���r͵Onkyy���\Q��P  �U���/��3��e^������c?4��q��@F� ;���3Z����i�>^�s�{2��f=3 �_&����4�c.�1�Fc���Y�xG�8��ڹI��Ǳ��xUR�i�j����4>�!un�X5|��߇ps�'1����>�*��`�~�4�������WN�ͩ�MS����^iئ�b�m���:,:K^�2��9��u�;�������d|̏�>��g��C��ѱ!>�&�%��c�c�3n�f�9v�����x��ż���f�
n���D�.��$L�ua��]��W���H�}�0����NR���Ȅ����g=J�ٷɐ6�m�.![R�ϕ �ؽ�pW>;�ȃ��9@G>�����97	�.W}2��^1��{1��l�7���ްgy����r����9c�<����N\�ѽ��~���{��T.�7h �^]<C�Y��Uļ'L�k�?�L0�եO�@Ϲ�� 9>��������Xc!K�6��%�儍&֍���MoeIX�����\M�QO���A�^u��z�Dg��K�Z�P�w���6;]�l��2��g�/� �Z�퀶��;���B�3
�s,F^�ȓ�*r�{��W�M�Bثo��,Y�(�WO(8htE2��9�%T��.af���i8C�ӛ�1��Q�xV�S��;{ ��	E^���(�0�r��]m�ϗ̜1=��p�.J�K�H����XCre�����Sh0Y��-@��E��cR�����ͯ�2��c3%�\4��+��b:��u}�+It�?��g�!j�5f��o� j�߷UR� �豝�R=*�}�^"�+�q�`���^0=Y'�\�+��jZ݃+�[���y���z�/7s���2,�HX����nO`���K���Jb|�↞5a��L����w��(/_�Dβ5E1�H�h�l�A�b���lB�G���-�+�Ey�Y�Hk���{��v���uJ�n"�é5%�#�� ��uvS��L��)?�Ӄ�k1F�������c�A��Sp���ɋ���"Y�?1 Lm���D���Ĕ1Sjdx�̚��qz�Sp/�m�K
��������Q��/G�[���8}�L���M�Gcz_����	�8� �ƛ,�7����@)ކآ��<�H�F��V�@ԀN�ٛj�Y��P�Z�.��=ecJ�,�Y �q�ѲֻuJ�f&&�>�Z�&���h���oD+sڮL�����ĭEI�u��D��ky���{@YH�D�&cl�1g���M'�"�>>W]v�/Hy�B���5|�<�5���rאv��Y�9��!V��H�r^1]��"Iƅ�eIv�F��kW�3�%@yt�����{moȕS>-��͜��%�+b��`�6�Z��c7c�8O��a�{���+���h�MtӸ͓��NX>l'-���"��oމ���~0:t�@ҕ�v'7�S�}:��eA����?'9C�ʮ2������m�l�<�V�3^"M�]:�H�4\�c���+Q̳G%��k�}�UsH6l���ZORs��C��e��;fl��3z���?	�1d�s��:3v������Zc@�Y�)i=�*����O����"��v��\A'CU.�q��N��Y��}�G�zE�4L��Tc������5��b���()�Bx�ُYz����NN��u��L�[�q�m��(M��7�EiS�7��o����9�
o1��;~Q᳉�DḦ́&�?�2������@埜�kԛq�����h��sS5�����E��@A9��o�^�@���Fd�W@Bw)�c���E��ñ����E�H����t��Poe(Ք�x�3FR�ב(�9�A�]�9�y���H��*��Sbø�6�@�����D8�;���6��Ϫ&q�$�D�A&^f�"NP��K�وIC�i�}�F"��c�:��SmH�5���<J��"�cXH5�5��{��XDYG�j��;S���Շqr�vƍ��]��1���u�u��p�d�#ܼ�U����*��#Y�����ΐpm꽀��[dŋ���ָtʳF�B�Jk{��;��
�^ŏl��~�oD
@cɫ�j�G>��]��ZG��I�ۓH v4���l���2YQفsxX���x��W��� g<�3;��ф�#����j>������o;�gv/����*ŏɥ^��N�ؒ����l��ErA:��6�jV��I�yk���wTI�=��؛��o�g<���
!S��\�����|��	w�c�������Ω�8ua6]��+�d��Q��r�តQ��w���ɖ�1�����քdc���._��3��̘9�����mn=�.��fD$���-N���=���*A�:��+�����M<��s�z��ݓa��48��>؅��o~u+k ��dk"��x��b���t1-{���˞z�V���+�	t�/�{�d��;<e�%�+ᗼVJx��$:���Gu��n�S��đ�P�D��Y��J�0�J��[8L�畽H��Wc�Fp�s�j�W�@g�}fD4����3��g���_�[������FG�ӆ���X�4_��x�G��,#6�:�Aɍt^ш�d�Q�ւ1�[F1�+*��lӍ�5�Zs����RZIT�}S/��ӟ�!��4�/�M�9�Q�V�F��w=td�{>���,���M��q��s�u���mi���o����!����L��R�J�L�G�O>�2UDI���ؙ�ʪrt��q182hۯ˹.?+��ذ�V^�lX�DMk������f�`-l5-�~\.����9�lh�0�Λ�N�D�����ۊ����ϩ]�Aj��|v'�̜bYe8s3�ywz/o�24�ƾ��{:w#.��֥�Z���O��A�����vV�kj�"2��\�R���G�i�l�~��K� �  ��^�q��-�kT�^]~=�{]��7���|��W���n����b(���Es�Odo�$���ѕ��-��rV�5��,$����6F��A���_�	�d�1�����O�X�͇�08�Υ*�L��F����].�D2�:m<�HgR�GtJ�{=���	����N�����Ӏ�f��A��?18Ic{&bk��e��ی�����(^�硳e��?����lFí�=�l� ��Lq|�}�Ĳ���a��3V���q-�W*�$�Ġ�Z�}= ��%�Zj47���k��rs+�W}��t0��ɇ�"����a]M��k��8�7<��b��z���Cb�q��qk�9O/�|�=|\)s����9ڒ�Q�W]�������a��ihk�x��y'�4i�1�}��잧�ٳj�/�۝L'rx���\8�KEtj��,O���6�C��_�����~cx��x��%�SVl@\op��l�H�I��q���]��fh���usسf�SR�`��^�~|�h\/P=�'a��ʐKw��3���>0��ڟ+��qA�G'\]%n�"���Q�8�ǎ�>^�E��Pm|o���D#��t��݉8�U��\���TI$ux�1��^΀�I_z��y�͹b�АVv���.�'n�[_�]�k�鯅����9�2�x�۴,eD�z����š�c����~tt`U.@�I��kh�;��!A��e�����=�p�o�|�m������$��b�sbF�~�M����N�8[���7ͻm>�%K�<�� T%N��j�(��8�aꈉlʬ���dWY�ES�Y�Ozzڻ�]>@N@53�'/��<�'	��i:�+`��q�Fh�1��
�腗��:���Tƶ�Q��j��{�H�����Y��?��dq�W�+í���M
���YT]�_;H�<�1y���/0�����5�=�)��k:�UC��onX�����엺l��p~��t�8B��&>��"T�1V��|�5��M(�͆8	���>}_��!�g"��m ���o���7����:�
q�"�Wn���|�HJ�Ng<i�C{��-F�֡K�έ`pZ���x���������)e,@�=Z[w��6h�93A��I���|��Ȑ}��ׇ�[Ȕi�Z�8���<��XeB��`,��LfH�3���;8Z�<�(ѯ̡G$�D��k>m�r�&��6ġ�/t����u#��bE�:IMX�=����du��	������|�g��,��	����v���κ:�n�<�CD��y��z��YO��LY��[�ƣ�>����r^xf�m�������u6�,��Ve����L5Qu�?|[�_�b�}���]+���W¾�u�:m���F��q4��rV�@�8y0��o\�����4��N}���Ω��ЩԂA�ͨ[l>=��!�j������2�����;MQ�f`)a�l���!Ǫ�R�lRp���gp��<��{WA\��Y��u�L�-+�|ԃ��3�Xn`�E���K�Y����E�1��aF�qa���;�8�����:��d����Q�|�|@o[:j��a�[��M�����Ǖ?vi��8�c�0H�'@�	]dX�h��L�N��?3�Y��ю� �9�h>xk�Q�7X��o�ŎA�l?Tn^�P�V���9ns��"�����X����a'���յ���I�q!��m� ylo�|XB�ܼ]���~�ߗ�}�	ڧ��iɯ�Ư���ҏ�b3��^�	�;df:!�L
��ӏ�e4��pf�hA�C��y4���nͮk}Fjx��e3-����z�Q��pΘ��EiJ��r�{��[�~�Kxʽ~L�9Aû%q�7;��CH�W�:I�Bn�{.��ف-���7V8�ڱ6��|�j3��?�Q�U8�@�@��[r�r�E�P���*<���5�S�+�,�W�G��Q��M��d@�!�F[�7-;/�~��Aڏ}_��)OU�Qb�����ѣ��w~O!�1^)�X�Id	TAykI�����ܢn���³9f��M_����>��e�_��0V�вux����YS��1aǂ* V�>�{Y��B�i:~�&�����)��|V���>RG�͗/���Ɨ&��=��9�i4�\
7�_���c��[~��LFT@<���&�̾�x���债ߪ����֖	YKM�:����o�\���fFDl����4&�$�>��bb3^;�#eo$�=�3F�G�Rg�WCS�5�t�OS���E��F���h�?S�(����
n�����B!Ht��١�qf�K�ج����4ܞ���H�q�3A��5�����]:*�sOt�h�;��2�0=�@��S�ym���R<{��g<�e)@�nϗ=�?ؚ�$�h�+e��5�Y|��#Y7��iJ����=�,��RN����ث=�A�*���Fp�SC)a���������w�:�|L?{�3<��.�a�,���w=���H�"�cr���`�;u�xf$g��s�[�����IY��j��$k��U7�Rv<6�o�����qwX�+�G����'x^y��~�n�^-�V���7��w���7��.(3w<��L�����R�&�p$A�$h	pY�2�1��<:�s�l�$:��nI�(<�����U��@��4���hL�I�񣗯z�jyw>=�'��vΦ��7k񵞄y��1���j���.a�Ά!%ˡȦ��쭏ݨ��̀�y=������4~e��ȗ,'�� �;s��s�H���m ̜��捏{�-l&͊d_G;����|L�H����v��ٶ�#�}��]O\�Ѕ�M+~9՜|mv�F	�����a�K�a ���PH����vQ����w9�`�-v�Yќ��iMq�kc�sb��}�|�sD�}��$MU{a�O}�q�A��f�cn���JS�7�j���w�O��#���gY��)�騠��F�*���v���@g�������î��k�rY�SwROo�ݨ�PF�nO'nv�(�l��3�w�?�l�=n)�z[^�<2�ݦ]��,��D	;�	���b�\�n,A��\�]՛ʩ=w�#�9W�>�VZ�}e��)7�]0*[3[ӹڸ��e/�3��ѽ=G37��� %�r����px:P#���T�����`"��9vr0D��=��if�p��5����>q����s,��:C7N`����NQ�k']�Il����ߠ�دc^����)/��@r� l�y���*������#ǡ����97I׽ў2�뒽��`~)_��ճ՚4 ^~�+/5�ޛx�1���dN�7�ݸ��#{��]��`�~%�����
c����rD�̆��aj6��
v3R���Ő��/b��r􌑴�mF�D/;"��QJ �l�X\ê9F������/��~      L      x�t��n#Ͳ&v]z��0�ZXݮ��b��D��(�%�%�$Yb���)��'0��m`�m�a�o����U�1�EV�{k��R��/�0�F|�q�6��\�JX�;�0m�ٝ�if�{���\X�}��qV�VQ�ԦQ���"zg�c��]_�~7��}ak͘���c��\���x��=G���n�����n�mT��[��Y��EV���Y>�|��с�ݰ��/\���jc�.��i��5.>С/.<\�lŒ)˘�]K7ӈ��h%�>�(�\�d?�?�^y|�Ox2��]��~��Y��l��~�w3�𵻴H�(-s�ϒy���[��׉��~��`K��@{,�U��\�t��~4ƫ _l��-�"Ԇϋ�����+3-�_cz��&��*�����;/����5�,�N� �k��������e�#�F�\y�f��qL�`7��Z�|�uTp�u��ʫǏ��o�V�2<�j���ks8�;�;�����u=>9h��P��ށUu�hy_f ���d��t�Ɋ��E9�m���Zھ�䠄��wXl��i�(ӯ�~���� l<A�'�s.L_�����������n+����>��<�	���Q�ү"��k�q/�1=:jXF�=�N�����gx2<?���.,Ck�d�3��+�9	O0r�-� !^=� ���9���X�(��ި/!~��u��m|�a]X�6�f���V�����a"����߿�}�[xRNP}��]�Y�\����1O~<��*�t�����Mu/`�x}F,.�t���ˊ��=�n���^x�e\X�։����!י>�|���K<�t��>X�d�%\�(Mr}�f�]m�����o���B�b�<�#��X�Dpw�����\�����'�c�0�i��2^ݗ뗭i�~��<���[g����a��^X�6��E��x�E}���EO�,�+��?�媄��k�یKX4��u���s��u肹6\�8��y�^�����D1�6�gZ��[��s��.j#� �mk�<;�Cx ��A��\�g2؝y�N�u@����5�x�K����A7J��>��g�"�a�]P��U���6�s�ج������Hx���䳲�v\o�P.����tR,�A��k}|���9��[r�H�Pz	.�JJ�(�AT8��ś�Z���;)� ���n���]�f��w��eJk
����Z��A�*%�1ϢEQ���Y�.�<�ch�(��ߦ�2��HԖs��L8�j҉��Q������#��pPod�l�±����xK:n�rź�+7�E���Z��F��d˶i�hr/]LO���օ� ��,D��N�����q����Z�O��;R$l(juiy�K� ������#�n��~��A������~��J7[P��\O{M�(4�����|�6<�q��7�q+�L�ļY�� ���A��枮P1MM\�#,�}��Sh�K�]>�hŧLY��!|	P�h"�m �j̦i�_^�+|��2�ԶC��y�x�X2;*�r��U'��E���ki��fʳ�P?�d�kY(D~��Zڵ�[4q72�g%X���7�2.غ,7\1*�p�m�Pva�i^�ķ��@��82LԹ.)M\��F�:`�A٨�r�ġ�x(Fp6⑃��ʥ�ܟ�� 2����kݴ��^�a����e�u�w�P.&��������@>	��_6���	��z�V��4��W̾�z:4c!�7���84�ct��f�>9���v��s���/<Ckl�(ֻi��|�?���u�B�������e��L�y�OT?u�x3�>��JA	x��Doe��p��ۜ����IvA��5y��uGR��R�@;��&a���r�\����64ly�|�[4��������� I�M�Z̓�a9�\�໰;<��F����QO��ԁ�S+�K����W���`��T%��z{&Tݪ�}6�C�XX������z�9�?ao��9z{�\�0]��_׬�h��P�-�\��2.�X��8��	��u��M�>�ɀ�7�"�U)~��-�8@u�[�}�\o�@�l����R�af�T�C�g^�����֠��{��<o�µ���p/����=Ч���ZA�6ZA߅m ��*a�Q��2�Y��-����b��ŝi��p����n��7����Q�ё�>%�dyM1/����-�� ����}�`a�e	��6�?��W��Cg�뿟o�wh�]�/|����?����x!R�a{�2���Q�2���r2�Jp�@)���4n_H�e��8 eVD�7:�L�F/͹A�gHjѼ�������(>mG�w�&�T.�t ��<6I���=��{��I����ֆ�c�qż�
��S�����!۲��x�%6����Fe�O��Ag�������\.�zA��wK�T�k��>�x;B�Q"� ���h��x�O�A�tOC����=���%����t�Ka{�-wc�� 8EK�-
�7�^墛x�!Tl�l��nyz��[2�"��m�a�;��T��*�"r�\�>^j�����f��th�_�b�։~yǖ��t������I,�m�#?�F����x����vT�^�U�lK8ڤ�c����H��EhkB��~�����O���}���S�}�3��ck��5�@f��"N�<;>~3ZLK>>~�E�j��+�s/���%����(qՏ�j,>���T�E�(8�ЇH�CD��I�(p�� l�4z�o���*&Eש� V��>
]�0���:~��܇�=f)�c��!Ȇ%sP���6�L�Bx��kҴ�Ս�0�	��)*E=�d�Sn�u��g�p4��4L�F��@�{v'����E*�DY��5�P�3�7,����R�Z�M��6_ʗ�d��l��r���Ӭ�Β��Cr�Ié��1�~���8�������b�����o�~4�f�^��M�g��Mnf)��Y-7��{�@
�%���0���f�t|ҧ"q��|Jr�2�6�M��,�����Б�^P�� ޖ�\MP���|�|���B��4@x�YI%�d���|�g���f�%��� ��.�i�;����Ǌ���20x�`Q�y��>�C9{��T���)��h��#�2�	k���׿�D�����=�0匚�2$��3�3dk��#y����R3����r	y�x:&�;�>��Hu�����H/�ԡ	�����Q�LU�_�}��epfQ2l�ܡBܟD8fP�{q��pm�2��Q&~��+
af��n��c�"')-:xT��^�N�M>�m�^°^j}�?0��!�q�o��N�u)��_����S�����\}�	���2\Ž�s�Lm�J�[8��(�?�KIr��6�3Pp,����,V����x*G����/��4}���Ҥ�\_Dq�H�����*3�~)���z�ȴ@���+we�f _�K;��5�v/�i&��	�(_��L���{߬��M�m���
M����s%Y��(|�U��ac�24��}���kˢ�Mg�Ē�u����k*"�P�X�j=����?`�8��F���-W�4y��rcG���xn
(��"���nƓ�J��u)�\aLP~�`D�o�oe�/�;<���w����Vet��~Zi#ו)H|�ܥ8�[9�`��Ga����6����d�W��r��چ��`4�������U�]Q;^�	����ä�d�U3��M2����	sc;xK��I��$/��e^ô!�ܤkL�-!L����n�܄��Ѳ��D�Y����dn�T�"���O�kW��t�(��^�V>�=��	��B���W�N!��yWu��#�8���Py�ԁ1x����u��SRY�F�8lD��U�]��D�t�fY���v�P�9h#������3NvEHw���X�pjʥ��|�4L�T� �숚�ӧ-�s���9�;���p�T'^`��(\&W�୰���#����`�=�����U�I/�
%m >,��[E�v�����K��    ���b��cl0�b�����-G&���Z+݃˘�MF�6�_�Tp�ɩ��S/|Ļ6�&�
s*��w�.�^����-�	ϒE~�Tb��OJT��k�=�0�W���	�9�$|�[�+�i�:��2�p�3�x�z�%݊�xL�%� ���Ő"c��Š_�s��m�~\��;���
Y-�d%��e��<e[�ו
 �~��5f����a��[�2D_� XL�y�n΂��q0�);}t�\��Y�z�Or|��t֡܄-� \iL3�b�_,�a�f��b2�<����+S(l�/|�^ ڏi��rگ�lD��.2V=�P��3����$*�0݇	��;�_�o�%4e���0�����3U���wC�������~�3�߰}��6o
3<m.<�g��� �p�nY���nK��{4_V�E3������S;R���|*ܮj�����)3ۍU���8�ٻo�-�>��u)����	��+���g�]O*M�٘�4r�\�By���m�e�̢�'��$��l�$��`�������7҃�w~��>�������3��~�~�m���HdZ�E�B_׫1ۻJq`E�%S�U�g�)O���c��B2�V⣡�0YQ�ܗ�β<��Q���M�N��[��~����w�TBA�G \�� \�<����3,Q ŗ�
l�BU�İ���C�R���w�w���Av��[�?�j��1\'�n� �����z?7�ܰ5�`3�T�a�&��Y�c�j\mv�#�������V��W	֦�������*���er���6��ʦ9XQV.t����)�4n>[D��ǂ�ȴ]��!C}�Gzm�KNf;�
��#��ǂTNu�~��7�<�Y���
sz�4m{t���<Ҵ�(�H��4�Cq7���ǽ�.0���3�0-stU�o�Q���u��7դ��9'Ԃ�j`O[��)���r�Z��0T���������kW�� �Z�x��}}I��v������G��O(�� �X:���� �=ڿ �ű�7o�'A���@��ʐ�#SO���(�X��?}�G����	����؇h�$��&���j�) ��Ԃ���Z\%�L0|vhh���#آ�H���횲tlӁ�W��f���r۳H�E�{ _��pʔ���bosP:��:�QB[���fp����c6-�'��3�:mJ �n��+�|L���qM���SU��
8"��党�7�N���/���[oe�Ҙ��\�h��?~���_�΂o6�˳|��lS^`�‏9�+N��2�)*�.J)K�Q��������>ECBj�(r��隀#�.ݛ0��,�>�����N�"L�B�{�;�'=Չnzj�;9]�l�D�I�� �ej7(����?N�V��D!2$�����g� x��_^y��p���B73�&�Hӆ�R����f AG�?�`G{��>ѯ�L�0��vo�'�w�X�X��y%* 6k?x�V������b��v�d$��(��tn�[�Q�k��I�&����-H��߉���.U�	󭳷B	 #̅eZ;]��6�x�Y����2��P{J�Q�-Q<{����r��A�R�"��|�7^ ��L�YW�����-�����v�U�r��;V��l�6��ڢ`�������&=�Ȁ}F���7�"��i�9�om�?�A3|�2��o�u���F��)6o)�i�i���~�gIw�.?Eާ`ƅ7@�X��>aY.��-�s�ϊ��o_)���w���*焘��t�0K�C��2=�e�y��8*Jʀ͇ݮ���,(���rk�犕<KZ�+��E����M<���Sɂp=�e��n*�4ݠd:�	6���Op��y�Y}E(�~$�N�5@��/Z�{������e�Aӯ�Vԕ � -��O�k�{�!�,CkF"��k�k�`�x�����:j����Rm�'�Q|���� ���%�8�A�x��Y�O���¡a�$����,0}�L	�W�W�':�-���;&�Mc.��'L%J1S���U�GG�R˂��mz ѩ�7{T�]�\�������1U�4�r�T�0qw��MUH�oU-��ks0j����A���,�k��f=,�i �	(���h�`�ւj�l�YR��&+�G��?�˦d8�-BKM�3�@�T3q�e�C�Wn�e��I���R,��_G�y���!�ɾ�ղ���	��i[�,%%US;�Cy���>q-�=�a���z��O��C��祀$փq�H�B��.p����/���b=ΌS	q�6"�Xzgz�딸X̾�Ug�ݷ=����Q��q�� pZ������=Je��q{�3�m���{��(�@�[_���r�j����3�ށ)A���O���Z��h��.&��/��s��(k	�ֻ%�Y�
>I?u�7Ĕ_��voș4]	���9��F�����uwC
<4dK�f�Li7K!��ޣ$�λ@3��rj��^|V$ƥ��{�ZV���p���qVB̟��������fM޴g�r�_�[��'qSƑ���Vw�,������2����ŋ�0�$k��o�j��(#gӛ��7(��(j�E8�ž��h����S-�/���t�����ĮU����7�3H�='\ �GI�M�.iV���;Bh�߂�}�������"�*�jfr�����-o�e�GO�5�G�WZ��4�r�zɎa�Z�����-IN�HT��`�>[�7E��m��p�Y)N�(6[
L����u�&����$��"Z�N��H<=���*���wx���M�8*��]�|;"��la��eE*}�i;*��V�T�����"~2)�b��l3��Zqn6����+'���N)0ί�j��N���/ژ!}��s��X��`ATrĵ:j��	�����:�K��jq�a�9�U�b%Q��=U����Z@fE�qϐ�f�O	u
��{��'K��'$B �Rv��~��Q#2���irt (�R�`��Z8W�RC�9a��]��!-7p7�1?wˮ�ۯ��X�C�Fo��鲂�c!�Q���8�Q��_�f��u�ÿ����<�U��S�o�/���W
��g�~Ϣt_+5�>M�lKZn_,a>,"t�`�7j�޲�7JJa%t`�)�.���<prV��v�M`�L-����O>"�{��h�)W<�����DU�� 1aF�i���O"��Z&���rZ��X{TZ��uJZ��}���G����I_��{hHx�OnހX��N����7+V��Lmsx'r'���3o���9��o���<QC��!�C`����#�=G������Ͷ��JZs�	*��u��d$G߄7֑��ǜ��A(Q���}�KJ����}$����|�:�����1�q"7�l���	�s�� ʢ�}�����(=T-�#�?1��T��L�I��i�>FD��.e�gt)EeM�j�2Y��X���9�������=V[���{��v��材��%Q�k����'�8�6�#**�P�����T}3�T6d�Q
���x��S_nQ`kw0M�����:���u�e�A�٢�K�>&WaF�����sR)x����ey���؛�:2%h�= Xx�g"W_�������I�!^�7\�"�J������_@<9.���⤼��3��|J�QOY�Q��� �w�]��#�|�HV`�.ѿ�R��
[�?����ax�a����!�I���j�&��#Zu0"�
I�+N ����[�\��`���l`�y��h*�����\^3>=p��"���q�����V�h���'������{�i�E𪪹_����-��`�C�0/�+�'���~�f�2E*�CO2LP���am[�)om�>�9�}�a#���#텁!k�&��0кM:��8�Fk�&s�ܞ��U
!e��(akԮ���|5ZT�5����MB�z�*Me�k_��m_-G��)cCDyU�XX�    �k��;�&P�݄�1�4�,����$���+$p��&�w"����lMB�d�s�9_���$�q��9]�I�:&>��g�\��ʱ�2����(XD�����0<&ı)�&���Z��G8���R�������U�c����Ǧ{lt3pG���/�_}�(����Ծ����/�fmCd�n�\�||�W���$~՘L�׶ihC쏦[V?���m �Z��?Rb<e�N�S��j�c���)=.۴@�>#�W83<:\�6�ą�jj�9=`��HQ.E_7��m�ث�h��2J����}�Tc��d��]mXE����������x��'�m0�}�eRG�w&�S�F�u��ZepHQ�"@�sY�&�|���}?��ӛG[>�X|Zդ��&�-���i�>@�Qo}���:iGT�([a�s�ධ%h�v����f�7��
XX��ö�(�C��� �/o�����-���ظ�/`F�/r�
��B<��,f�E1?�����l�|�S��ݜ��VUt�-[���'���S��DT٠���1�x��=X6��uW�s�vd=R8�6(��e H��_,�)���� :�LK�͝l�"nW�M��d�<f����-|��;�����ֆg-fB�B�Q�-��0��JE1��QW,9�9Q�h���#U�,O��m>�DA�.m����s}�����k+/��XGĭDX���p�`��K5�s�bZ��܁�v/-��c|�<��B��Z�j���CpD^˄wb�0fq&���+��~�cq �l��%v�� �c�5tI���`���_�_���>l��eӝ��m��(��EvZ1��fX�̛�j]'�S��|�.H�&l���H��BB��<�g�v?}�3p�E㗈�@��� ��E��h�js��>G�bᬱA\VW�ӏ��RPl��:�{ו1�C�㱀~������������[�(]K��ڎ�M2�ۍls����w��Wo ����Eَ�ݏF�i�p�(��bi��}��I?�$e��ڂ�C9eAw��N�#̀��Ȱt^z0νx�U`�5��L��u�b�z�Z7o;�q�dv*��F��ڞ�&c�COo@<�V��������*Ծ N�Y:�։c���+A`7�2J�z��~�wp��8>x91^�oC��=M�.�U��7��!)4w����_���a|����K��A �m�
н��L����Ӝ�zC���ҳ�6�=�=2�d���m��� ��kq����`ڧ��2<��}�PwJn���_�E]0�(Tq%Wi���XO�)�ܹ�e_��gx��n�Cg���;���g0�36e�^�ã⿞����&�u@���l�Ƙv�/%
]�6�yl�ކ[������U#|�f'�x�� ��D�o\��O�SD�b�:ӛ���:�J�e����|��ox�c�m�&`��<�\U��e�ݑ�|�j�6��5��!�W) �^c�n�!;m���X�׹�9�J��⮁}�&�H���C�4��z����Tq?��5W��;D�#:���7a�p�v��lL����i��uP���x�ĬSN�O��`�
��HA��ϻ�j��h���&/ �mCY�ƒ�[�O0�bɵ-�_'D�`����h�B��[ηTuh�!`�h���	5�r��_�uV���#�y�e?�V��$x�	>?;#�]u�����(.��XRD����ܼ�ߐ'J�C0KX�(]��Q�Q�*lp{=�QH��^�j��]�)��@ke���-���rj��"�e�!:�yk��C cլ]�z{<�B�DJ���%�o�	�,�c9u�Ҷ]����?�j��u+�2WU��|ٲ�Lt a:Ӹ�)�p	�3�3�&^� ��d�� ��fj	��^4Ê,M�7�њ��K4d����!�~�����m��@lj���A�O$V�Y=�m��ìJ���ݭJB"�}���$���#�k���OZ<��
�&l!��VL�G���U:�A�g|�@���gϳdC,[6\�.�.LDL�����l�HT�
Rc�W���tQi���[�o�Mߔ�X��� ��(_���X/&�lY�t#�4�f���q�x%�� �}�v���e�G[	��T_����U\6�����S����-+��U�eҺ$O�I ; K!��&+J��g՚��Js���}�-A�F�:�Ϻ�F��Z)|K6&ڠO0� U������?���y �M(�,p�X"��D ��)�W�#u���ע�ET��T�~�~���o� n�����l��xuC�PaՆc��Qۤ�"���e�e���ΰ;.Q����v��c�*-x����*�G�Y��ěn��ˣ$9.�8�</��6����H���Iy#�����O�4�:"�ttMCW����� ]#ik�ӭ}׭��EN���f��m��u	��V����ҋ���Քo�kQ�zy��CqƦi�!�3��L�>�E�����p�E&�6ec�"d�뱈�~߅�V����rCh%�4�T���:�氳��Z�[JiT�Os�L=�"6�Ͼ؏v�'�`Z3!�8�����/��2����]�M�Z�律�l�*�c`S��	���f��΁G5۸���C�E�H��.�f����\w2 �Ch�?�K�Q��FIo^��V����;��ZxCX�I�5�_����;Bۻ�,_8`��7o�IH�4!�*͹�����!���S=�-ח�9��4�_iy���+��GgSP:�M�
M�ׁ���h"�oOG9&&����ط2?O�X���6�e����Q%«��Ⱦ4H�Y���)��<k�S�E���qL;�����Ƽ;�9Ce.�&���
H�cb1>�o"q��
=g%�BV��Uor%2x���9��VH��ޣ�ˉ� 	�6��]�k�R����T�uCl�O������:��`zjC�ŭ�,�=(����g	�ED�U���/�KE��%�Ny��A9[��&<c�ÌB<�e��S6[�-[B��U��S;
^�>�f�o\����	(Gh;2=�DX�!#f�S��NO|�<���@Ob�(�3���׻P��=�:��$�u3�"�&��e<c�d�(�:[�x��%qL��̈;���4m�[eO�^ij�Á�%�&����4��ɻ���B=�$��56��55�S����!^I��ul-� \~���>�%�7�ԣ��"�F�!��c��joؿ&a�-���n��Ʊ��Yu߅��������5�\QzJp������Ǔ�Z'Qr�o�kE)�����߽����WC@j�6!^b�6��N�3n�R�"�0�R3�i!�%�eK��q0Ñ�U��fo��YlO���D�ο�?�!���J5Eh�ۅcỊ�h&��bS$�<N��� ��TM�>��5��U�w9�2M�b;h�mz�_Q�:6j���̸��)���'��K���n#D�X13w���K�a*8�=�<��5��/�����M��*!����!ؐ�z�cS}�@�,��x��>�}|(԰��Uw���~/���V �g�1����Ly��/+񦱀�T�W�A�"{C��[u�j�:߱a��CdJ�?������Ň#�z~^A�xu:��龀�O����%�jA���W��(��㇎�nO<�;���Y��57zt�}S�-ǧ���RqEZ�EL�(·8`���P�t@�ӽ�~Y�:b���vr������)l��Vht��8.���-�G��Z;UZ��ǖ�"���N�&]&�*	�Zc�����PT�� �"+4��� A�@�i�So�F.\�r�\�N<"cQ)�Mr�H(EÔlӎ�5��̣�tް�&K~��OY������_%9���ˍ�`�5��[��?~(m�Q7�(<Ӿ@�)�y����z���X۵�C|(�p��"B����jh��`lm=.��3(܊؎:E7Kc��iw���7�w�ZJ��-�8�b�z���x�����e���ݡ�+���u��������=�"�    ża��b���#�P���K�>mWR�<Ձ��*�����"�u�%��	�t
�������+�xeWn���I!kD�{�/��;Uj|:DE��
(��7�I1o�]��3r�S�M��rd�8^QǇp?��&#��u��_��,t�2c�D}�ȝpDp�h�`��tT"q݉a�M��`�`�o��ʬ�t�<��1Gh��ԋUD�'�D��3'�Vi-�W�@����� �7�iy��|>�M��,�\`M}K�UN���~|�>�C����*��w�����Iqn@F�>���C����글����O�.ٝ���iq�['��Rj�l��kk����fD�<�Q�6>B�; ��<T:���?��ѠZ��#16X��<mf������Hѓ�؏[�Ȫ��V4]u%��`H��b��⬄9���sW+�wo6y�Q��	�ܘ!���*�4�0�H��n�E�y�T����}��s?'B��V	,p�qK:�-�g�*�ô�&���5LJ�K#�R�a)I#�%�H�`������7[��T�aW���I�`��<t�j5K�.�w�jm�\�x��GAMg)�+�A�e�&*w�d�q@ ���4�O�Xb�-S�zT��F�9�Oe���2[�m��:&���=����_j;�/A��V���cF����E�w3�	!ܰ�F�uö�{5�)�VW)1�D�UD�3l�"}����t��+RJ�;��Af�c%�>`�q%����:��I\�����{t�PxN�ʅH�
{C�*DAF�'x��,����IWIr�8d��G�k��ɸBfXB	ӂ'��A�Dc"E
kH�@$a�L��!��xZ���D���UnT�`n/��}Ñ#���-Fɱ��?6&&p_��)j�����O���_�ˎ�o�J�{x����yH	s�)a�5ӌXB�A���T��dH�HЬzM��(!� �9/w���|�/�^��Y��y�!
똀����NbL���bw�����?���rI>�*��K�VY�����;\ş���#)T]��}�D���c�7Dqz2��&�"��Kv1�Y.������\����ӑJb��T��$X�����Aź��N�k�x�<ǩ�uD��~Y�����B�-7��ʵ���T$EX�^ �jLFG_P�������͠��Qzh�e35��0����\#@����>���A�8՘K,)�7[F��:�܀�.�r��_�	D�6�~��N,b�w�B�|��ۨ��U�̂O��� 4����Y6ˬ���,��N���MB��^E}��vWy�%ݔ9+�P�a�T0I\�O���?t�����!��~z�z��r5g&�O)�#$"��iC<��`��<�k�K�h��rf�fNc���6��L���	7M�)��&��>�K�>/u��D��]|?�n�q;���~v�ɯ~�e#4yg��b`Y2��TF7�{]^�E��+�z.�ų9��(�J<|���ri�Ҹ�pzwi�a���H����c��na��)AX�
�'Rw�#�'ӷ�u�(��M#$;���O)�??���kْ嶕A�~���,��E�F9bV�G��a�V����!H�����I]�4�Iӫ� �b0�D�R�{�g�Es�0�X7���ZR��8-��^��ݽSM/!,�>�@�W,�J��a�}�vy	s�7�ZOpp���AiFA�U��(Ps�6�Z�6a5"b�xR˳��Nm���h�R���n���y��� ge?~��C��u�Cx��M�$�9]�u�'�>���ȵ-م���W��<���6z����b��c�K��ZΠ�ܘ�a�]�g�� �ap�� z��T��{�<"���Bdݺ�
������뫴<Ip��̪H#p\h��i�<���?�jM�Y�R���Hεq�H����q$Dc&�&�j�

����rK�m �j]�'v���\.˗(v����`���{���c\`�:ٚ�¨����*��m*v����wYBA1'Q���K�'����u��=�5���6f�?8��_���-[�]�){����}Oi�o2[Ri��,F� �7_����|�r��+�_י�����]ߧ�Qk&0Ǝ�W��'z���p4�?�J�u�U5H��IN61US,����5���"�g~)HpC@'����ӵD�TmH�\�5C}�f@D�lϢHќ<?�G�p]�Yr��
��>��4$�8��GV��~ݒ�2M9F�uM�#i!%Q�pxȩ���3z���Z��l�݂�=Oe���_\��W�"j�OҨ��J�ح��8��s�n�gw�&��-�:0������[^	��Su)���Q��$��T���H�������r���L_d`(~����o��{�����z��V���Q��ɐ��_�Q��7eX13���ٌ`��!��O�=�>]b*Z��8�D3����=X8�+�L���ѭf�^�����jZ�gh�Ȗ1[�.�y�(��LoiX��n� ��R����;	���q��@����b�1�:ݵ^�0��BM{��?��:!���,�sG`W9h�D9Z����U�[�ݛX�q3*���x-�7�wG1^��\ϓK��zb����tbG��5�C�U�O�����!':�%����P<����]qs�4'ѓ�,�bI�6�t��L��R���VG\=����(�%�L�R���۝0�������s�Z�}��S=>�$u��c��SeN�W��qepй����4�/#�M��".�ڡT�!(\X/������@]��%QM��)u� z�֒����q��`>��Ĝ11W��V�DW}��C?p�t�0aD����9BU.�����+��-����TJ#��j��d4V��R;����AdB�	B�&���V�Yc|�@��2tlh�H���{H-�P+��.\�[��-�)�P�pd�A�WC7�c�ĸ٘���L���wv+r�����lM��āѼ�T8�^�bBW ����=���:�sP�����S��$���x*'���7m$�4	�q[�h���_A(3��?���_O�lVs�� ��˵����A(XW�Z]�b���1�P=����|fۖ� ����fA��LL�u%���0�#iY;�����#������u�ց�����HM
Z8�Р�C���(����͇2*VHI=������.����%7��$�>[2��Lmv��p����bF��YiR~��u4`hPa{ �{��'�2�p�pY�I�b���7��K�g��u�<���_��_�^y2�~�z�W��pCWmW���r9Em��J�K�9n�'&	v	�3W<͖ٗ�r�b�|ٕ�'fZ�(��|�?��}�ʣ�K(�R�P��p���Y4��L���nV}+���a����� ����/��}�w�d\ZV9Q�X��X����,A�+3�a
�ʀ#�F妛�+Е�)h����ﷄg�@��Խ[�1�pH�{��ȃ4=����U#E���3� �\�����2�:؍越
&�$��r��,�a���s	�6L��`ŷ�K�M�����z���sF3-๖�����eܧLM�H/��`ֲ�A�1�����O9+���BV�39�������cIܦ���@2���L'GrE/���?�T�0�<��� ���a�t\�a���!�8����d9O��v���V�"C�Z�CH�w��e�2&멬��Z�	�KoC(���$Ѯ"�T�eI�Ķt<%���VBQ�$k�Uh�y������哠`;��xH���(��:��'n�GB*�3qn|�����6kȼʈ`+4% �C#�`�Ti�L}_�>��e�B�U*�)���۩z;����n(�Q�e�w<������O�]����x�Bc�<}[Cx��Eo#��qc(�ia��װ$B��%_��*�8�[C������ovp�a�����v��YQ�y�m�[T�U)R���o���̔�R��س<mȓ    ����O�;[p軖�U�c�s��%r�A��{��Pv�y8u�of�t��2��o �J���Af�9H�/�	%�u��6�>Ψ}oW�}�E��A�j�k� I�1�0]H$S���U�m�vKL>l#�	w�ԫ�A�#R�p�l�!���Oj�]/��I��z��u!>_CH[p����&§�]�ך�_��E��U���H$E���`�d38
�?�$=��H����?�gv�4��p�w���q��(��.پ�.�֯���/�eң���`�m?B.�����è���������( �U+1�kSL�PU��=G�b�������� zpd+�� �eI����}g䫖���?HHl�	Ć}��W�:AҌ�Ѻ,��݊$$��$�)@����y|O�M��4��vҬ���y�g>H�@��=�EpX
���W_����B	��O���:�������Q�dN�0#�-����B��Uy�8��9N�-�H0d�<ù���u(ɫ<'��V~-��ΩIX��`C�FjRT���S�c��1-��t��-;��%Gᰞ���7i��$i��ީ,��q9p�!�o���Y�.{�}>�_y%�����hv��b�z�M�4�A�W��]�ݗ���q�{�l��W�� ��^����T���l�(���Y�����k��(%ʈ��Q�K�H��8_�m���y��������q�&S)�g�,	�Z�O�,f�!�WD��^"���n �Q<�������r�b ���7캫xJ��&f�>ͦ!d��V�!�m���Ί��U�34,�E�6'՛��k*�G�\�a���jvir��D�+	�<��7��C�%�ܔ^���=[f4 ���j���7QiveW��9Z���k$�v�+��zw%y�h��<W�sQ��s4EzKB���ύ��U`,*�{^U4\
��e�F���U_xj�#�"��I�<DLed�T7l�>�P��������T����2G�ۛ:D�Wc85��}�ck�z3NS�P�c"c��ͯ�C�t}vT[}.�H&W��5�s���|p˕�*�&W���"9Jo�d(��<P������/�bt �o˴��)���g*d�x�ވ�_�D�z`ʆ�7���wr��6��|%�T�ĥ U�m��&��L�D��"T��>ޚg��p�6�d�I$�<L!���lEY3ѭvY�FߤM���O�h,�/�f1��N5�n�-M�m���#o����98A$~��Ei�9(f9x~���7��B��v��^ ��8�������4�1;3�ȁ>/��<Mb}�C�ܵ#{!���& ���U�@+�C�I�a�6��(ߞ������!�Hߧz^n�~Oզ�s��+��Fu;6;�� �-	��*$d�S�,n�-Ai��6c߱	�$�0"ngj��E�N�=Ӌ������������M�6\�hvT�����gԮ�[�d�l��k2�(a��!t)�����|�/� ����f^((���>b�&��2�]�y!���zÂ�!`R�
�.k	R+��2F�`�%/bA�۪A�p�h)�Dω�\���4�D�-9n�Юf�ޱ��X�g�D���O��{CJ"ê�E�#����HTt�@����i$x�D��>KkV(�$5~��`���' �����l�s&x�h�9r;R\8B���9x�s�Bp��Gs�?�A#��A^�38i��u���>q�a�D���$�'����̎eG��'��=$NY����m�r�w�Y�k�~RF�e��7�UM7�~��������|!�̤FT�Pf;�91��e��9�]�$���7.ph"����Ƭ�b��?�G��ܓC����%������
��l��j�o�u�u[r���h��<m�o��Y�Ӟ������>�P8+����K?�S��c1{Ħ8�|�{>����J��Y�ǮR����Ck�Ȣ���_qŰM���
����%&�Ui�! $�N)�c�m̥��c$5.�ʪ\��'W�E���	뢂?Fwd^uz�1g=j���QuH���HÉ<?3����hзdyK�]5�8t\$�@�u���Lى�#$�?z� �l-]A�\Gٻjl���ȑM��d D&u����T^2ƃ#Q�-Vdk�'V�3"�W�d�MG�_G�rI�}y���*�7Y����1�p!0���MW{���%�s��+!XL����1���� o�7I^�M�=�6[�V�r����Eʅ9N|h `�P{��=�v�E֨��p���
��Nc?j�'�ͱ/�XEw�o��N�@2���ʧ�iEdB���CM`�K�9M������D˗x�յi8u���6Gw��$o�E XY���Gu�<�VHET˒�!,!�:`������i���^3Ŗ���֬�zH��VE��*�7�S�>�̫��0ɷ����2Q�*���J��#�[a�fJW���;�:'�F�z�g)������حĈ�����]���R �O��3���p)HH�*��q�{V������Y�N��� �6$©b/E9���'��5��+ASV�8܄7][�!]?ӼI���F^���z2�O�Ez�0a��'�GJ�c1b14$��o���A<�@�W����|�H�|�����&����{PiR��f^�(J��<md08�O���T��Bzl�l�Nl�4C91]2���u�9oBC����#s'���s��;�l	b]_��pqD�c��R�q������Ӿ�9��Y}�s	fg��WJ��Σ/�����	��� h���+q�'.J���7&�(֘bY�o�,a�����=�ZI���R�����W8��S��c�a�=�s�������)ڻk�k�鐔[��ů���6t�}����I�Ʉn�H'�Y;6\���)(R��u4]�;r.�Om���@Ẉ��ƞp�|PU���褈�ѩ��-�+Ȇ'B�t�4�ѽ�8u��;�A }U���um�;�οsd:]��[�k��Ә���|I�R&a�����ǳ�U��V�	ʪ���DCN9V�ø'��9�K�4����O�d�8n�;Τ]Q5���I�hH^�p��߭�XW���vl8�����T�L8ݰ.�7_c�ѐ���|]�H����޲��ߋXܕs!|p,F�}fq-��?�
_��2��:b@tƏ5B���	���u:O7���s+��b�#��rT�)���^$Y���M��L�)Ъ1,J�<:tＪ�Kl�>�R���{��������YG2��Đ��i�##���:�AH7O0G��� ER��+w0�x���jyn�����v���>C�	g��Ӗq��Qvx��dOXv�$Ij�l�J�i
כ� d�����������t���%��<��E4;�g�)�A��E}�9Q�%^�$���bZ�#;^|ϕ�}CYYD�R��~�M1l�hK=d�&��Q�����:S}S��|9�]�}U>���ͼj�
Mf�:ޑ�����K߄�w�A��òlR0��kL*n��D��&������#�%e�of��6�;�ϝ��I �}�9�V��=�c��
Mݥ�O���>=H��5?k�|�x�;��s	�[�#�@�eKv�v��^��Aq�ȕbB�8"��k��K���I��J}��
DEKu��]Zzհi���w5���|n�zX�_�V4������z80"�X�b���<AD)�"�
�s���{{�s3���LS,&�CO@Q'��U�����Ί�Un�PJ}�����0���j��Eۮ���IqJf��R0���G��jCp�Y�����?�nTZ��~'��<�-Q߮:*��' ��H�O�\��_�^�v9��O��f:U�ؚM��\��	�1�q2��7�n����U�	�#�+�:up���"銃8j�w�_�B#��[�c+%�u(�T~$���9J�<��nn��?䇣�W��Y�?~5E9Q�%��2d��U2��.��dF�w��Ă��	>��eT������}��\^3!��xHHw[|3�?8�r�	r�    ��F������j���$L�i0Dh�A�l �RL��XTG�B�R�"�q���ҍ;��Q��fL���m'B�"<�����O�UM�~������j��	e�6\�
S�(���A����(���OHo��,��BG"���=�̬��<.X�V�� ��a�w-X^�Z�1��G��R�%��9&��Z�gI>�G�M�4����Ȋ2��p?&U-�:Z�t� ��y9��I=�}r�w���g0s��lI�wտp��p���f[]S��+�/�#?,/�� a��Sb7���޵$��nhˇ��Vx��a���H2�C?��
Ð)[J���r�=8���pD����9���9&ʖ��ȆhsPm����jK&�fH*�1$�7�����v�3����f�kz���R7��|�Qy��$m�má�3j��"y��t��3�o:8B��Ĳ���I���zӠ��hszgM���6F�+c�׆̮��.ۥ�j{5+���s�bB	 Lm�Y%'⯝���f���]IV���U����Bt����r�{��<�${Ӑ�0�Ie�|Mѵ��Ҹ,�?YZ��Ȍ�à� 9����0��d*��	�S����D 1��*�uw��Y��ė��b�j`b���7�n�݆W�l���/Q�ki���7�5�Q�l_�{O<��0� LW�v����#�8.(�qp�j=���!��"��"3�\y��X�E�.O�$\��B�P�w6l8�3ᗣC�?�JHj1�۬���hXq�r:�
��
�m3�`6+�� N���O
�&O:�������u=��%(�&�#:$���9wo�����p��X9��xu���K"�x���P�z��<}=]�zN�S�GȚ.���e_"v;|���}���a5��[~ú�B򞚢�Đag`pA�b��S^�
g���<��ա�̒��V9�P���I'��N4��u5�GNp:Q���'��Ȗ8L4���[�n���`: �$�,G.,�'�(�;(�H%0}��ޜ
H���N�ٌ�y���$*V)�!���ٹ<��^Xu$����k3�)J���pO�=�����'}��lG��6b�<Ap���#!T+�	��3�����I�خ6,3.��E�>"t�dS[r�6M��5:���,���6�E#����W�^8"�Å"ώx����x
.&�*���z���-˷,Kw�1�wj�rϩ�0�؂Z����q��b�Y!�WO����ۓ-�E	?p~��yqorO p�,�1��������CRx�2]�k�oR$9yfO��>�𛬪%�:��T���/��f�����Am^�M����}I�8�G��"�ؾqI'�~�}��F_2��u||���Z#FpEn�I�`Z��S}�D\_��b�+��g4��j�5��y�����\�\͝L�J������h[PP�����Dא�� |���Bȼ`H���$c�G�5�����B���_�P��5��V̯9���7%�E�V42�/��;�V��6�R���5�<m�*���
J��tMv�%�,�}aٚJ���b�6:R2i����_�[��Or��Ϥ�n^��+�˪�9�U��oY�9e�S~������n �)���9�]��wjNw��l¶�a�o�FI�2���I,F�U�l��J#��G ���/��O��g+N]|Ì���-nf�NEb"ׯ:�`�0�D�a�D�߯�Y/�z�_�tx�lM �`X�@�l��)�	O��w�����)pC�y)��Sz?�0�j
'u�8�Y=��a�}����D0�� ��8�$)��[�h�פj��}���i�JSRg��:�H����p�*R�bآ�����ǑU4�,�ԁ=����[Hh|��lF���=�=�%��f���8�hj���^� 4*��si&��=I/�m�4��IT#Hx���a���6����X��x[h����͂A2Eas��<:CP�ڲg(�С������:`��v�t_�{���g�O�-(Ւ�U���C�h�Pb!_�8� '�n�7�ï��R^,�IE���k�Qs}��"��*�� Q�M�q�'�U� T���l&��ʬ�7QH�h�vT�q�]�n�G��v𑕳 �D��$����:t���A�c���yT��~΀\����AEB��.a��_�1���;oRo9�)�vw��Z��[�}Z[�'�RD%�C;Z1bIư�HhцGW��E��D�0��pܣD���f��uʳ�_ဵ�q��.��	țS{9v�����S;��G���~���#���_��\�I����x�?�LLƃ�W%Y� ;phJ�o��u|�)���:�?b����i������֍�̑a.Cp?)s\�uh�rj *�F?�#�+�C+-q�/_9>/#��ׇl�<t��8,��o�Z�W���������ɋ$՛{@QP�QA�3�
� !�?��9��������QR��t+�$�z���2t
C-���Щ��/Woo�nD��c�+k�Ѷd��B=�e�֮2Y���d'F�twy	]�#*J�B��D�O�R$�j�z�X��`,a�!qw��e-�1�E�]����P}���N��c�)6�VC~^4Sa�%�� �Ms�8Pi��ʷր��y{���k����Q�fM����ιUQƟC����"����]hq}k�%a+�x��n�Aښ2�R'�����@xB?��o���_���.��"���.^+iP�	1xC��l]�<���VM4O=1.��wM���$z��؅̏vX7r�15�#ӹ�����f~�ޑ�`���)�1��^�9y�����wX�_���Xu�n�w�Y�[�_��f��l�10��Q���]_@�?���Q�ȿ=q�|��?�>�^��gxݦ0K3´��P�<�k��1>��b�h�$Jm�'xN��rZ:�[�z)���A6����}���W��������!Z�$&�G���U��\Wi
˧��v�����r�Y��4/ 7���~�A��!a�A��B�#�M]՛�SϜ$��k���`�|{!�s�;�3Q��k��ܞ���S���eT��E��Pd��������g[��B��*l������:H��[�?��5$e" {o�c�%$��N��8��_s���E�x#��v��O�oad�M���s9�N{�a>�Z׋�	�z�8��jP��(�����p�ps7�bc���Z
%J%ld�`Kc�f�}Rj1VW���Ah�-a���3�q���	�j��Nf��;��O2�5&�|��f���N@��E:Ni
B���zwqzx@b��.�KٚP8�z��]T3]^�Ҿg�H��G����a��+��ߢ��W����BI�pl���GCE���x'YM+�P?ܶU.�v?�'���"����c�~n��`��|̇��A��oJi��[8���[�~�ׇU,��!I�Ah��IϚQ�/�?�*�g*��bI�cB�'��Ԉ�.����u\'�J��w%)��{��������I��l��c�(��C:u�����rҸ�Li���D�3&B�����(�E�L�/w����~�,ƞvL$�� �Z�9�D?��z�]v��[����1�
�"fSȱw���m���]-�D�d���L
s���n��W�$A�~�S8���C�EB�����	��b`O[�=���}x3�l݂�ɻ�[��*�=��6U���78����s�p���[͞������{8аv��O�;�ǘ��U6��Z܂� �K� �V/�
��`�Mi�rJ�ExVE����K���gClF�Hq��������Oom�`�J�D��el�D"?\�x�I�I����j�_n��>��+��$��\릿�t�BTYD
���Y��Q�U�Y.�09x����1<�+D��e^�W ��Uu|���$��P�����P�Ʀ���y_�I�&�!��/��V1������~�ܷ��(��y��V�DX
�'#�����v�٨�=ao���'� *  x�t�����"zd�_C�x��PQ7αrt6���GK/Q�vYD�&Ӳk��J��Pw��MB�Q��a�~VT^l����*�����dչ�m�^��-$�i�1MMj�q'�;=e����Н�q�`=|}{y%�س::^�q:Ί�7��" ��&�g�Pv
�����NT�!��p��i�,�/.��*]x�%���D9�����m3/ED��$`�d�Q�lRtD�o��6�1*"LT��3�����Q��zDD���<YN�e���Ǿ^�ɂ�=_+Wڹj��[D��"���тFг�,�Q��j�<�&�GEV�"�dM�>���]��p'p� ����ń�C�q��ӛ����w���Վ𺖯h_�1B�HЅA���ҥay�'�@pl���<FBmehn�ל�xJ�Q�8γc���{�w�*���԰��Λ��d؄b�v]j�*�XW~Pk�����x~�d�h^���u��WO 5GA���F4a�5v�yzD+���`�J��r��L
�"��,^'��ڔ"pZ��BUCa~C澅�]m|?N�w��/��,��C":ӯ+��y:*��8,	�
�|�U����#�n𗩫u��������%��W�A�����|2�9�X�q��~!x��)I~�BҢ��:-L�����wV���"��P��_j�'�Q˹X7��ʹIx�A���m�?���W�p�EZ�_>q�)�?	A�|Cq�����]��9�h�4���zl��.�i����I5�|����8P�k�"�����,��o�g�w2��RX�8����aT���-i۾2����:��9�l�s�e[K	6���#�`o&����=���9k�Q֙�����5�[=�>H#B�2�g�]^�^���xe,��Nv�*Y�rC����Xt5}�)3�C%�"c����7�-0+�9i(�D�N��*8�{�T(�0�I!�&�9%���I:�@��!.�LN48��1���k�En����2�r�5�F�Msv�A/27�J��T��f�#�MH T�ݖ}�����D�Y)��ڏJ���������(�6d��P��'���Ql�EG��d�Z����Q�����#l�r%q!�p�yv�n�1�Y��T�G,����]���?�fՒ��b�0�S(�6����7|g�>�Q�%	�M$'Z{��sz8�$�G�ó�4?|'��Bj(o5��v
Ԇl���(B=��Q�Sl|�e��I�l�1!�"+�"z5��u�Y�\~4��܄�lq�y��۷����      H     x����r����O�'p��ϑ�$J��P��_��XإI�������,
3t��9��UY�Y=޼��q7��Co�z�/6�wO��ӗ��7>�^��&vl4?���v�?���I���[�1�m2�O���p=L&�ZSu���n����၍�+1���:[��i���3��+&�l��û�����xQ3��?�]�*��X�)1G�͛��~0)�Ps�&��w��CK�%o�B���s��'�i>$��0Nywj����ɵ8��f��#m�ݲ������O��$�[�7���%[�`bI����K�����������q8r��յnb��˃g�\��B�ۃ��|����u��q�{29%�b�n�r��R-%E���6�/>՞:��ц`�N�����H�o��}���7E"���nr�����$�\]���t���������R�X�[��,��.S�bRO�S����q�)"�k��Dםx��'RJa��>��U%OjB����f	ᜣ�ʔrO6z���x�� -��R2EY���f����t�'�����o�ݥ�sԘ��d�|�o�~??~��]s�Zsr�n�
������V<[��+ټ�#�Y
��a>i�9q1�w�hK	)�>f��a����n�_�4N��x��Lˉ*�Z�-�)���c��6��q?~y�Լ/d��]`S�,���"�<� <o�=�m/�W���jӊ��{
�WS�M+�)5m��)�qz�%����EPS}�ŗZH�i.�+Nx��Q�:��/9�>�% �yҜݒ~ZTp*v�6/�ϴ�'�������bH$�q��h>��W���c�F@΢�������F�/�����7.�ߜ�����vs�$�NG#6��Ã�Hpg�X��f����8̏���iH` �����K"������~�j��^��/�5�ND+�Q%,,F<�Ud ��ąR�547G�lٞe��Q��ö�ss�\�_�K-4�A^IJg =.ڲ>B	dB���9�$�Mڣ�o��q'�&.dh���/�)��67�i.�P�&@���5�ov�9�1yO!��n�
��'Ԫ�M+�E/��>�}6��>�$Xw����Jc���C�J�0�����DӇC"-�"u˫-���?��~)���W �]�A~f� d�)Q!w�� h��?��C����$���.�8����/q�x��*^�ږΉ
p�x=�\-�پd����jeIW���FzS��.����S�����v��у(- �X��|I����I�}����H��v�,h'	Lh�EnN���o>P�"�%d��U�kE��~��mO� ��T�۳�j�?\Oت�5ԫ�/W���as�	�8�VX��pw�mT�&�%����w=��;���.�����ɤ�b�'��o�Ä�Rg��qBμ��a�$-�4�E�XY�1D���Z�!^R3MB �A��������
�c����N�T�#P�� bl����j1�~������M88<)ګ�~�?�uy+̏�p����*�;��g{�mF��i)��\�a$�_T2�GD���g�PfT`/�3�t@��|/�c�?�{l/*H:im�ʒ	P�9�bV�A<��t@�hB~�} ��	�gr*s(�LX��g��:0�H�tL/�+Q�F@=�����J/#�xr|��Y��p����^����j����I��5�����u��D� ,M����:<))B��]����_�4�s���|}�J�p��#��������4<�j�,BA�kg- �M�������sڥ��0O\xǂja�(׎�/�s���,��"h��0X} F�Q1B���*�!5*���s�`���+��a(@	�̨������x���8���2O ���BG�,Rl<*�g^M7��8�.� �+�bϐ�z�~�i$޼�M����r�e7�Z��B�N�A�>m����A���*���4������)1	X�3���i��6�)ihL"��D�>��@����z��Q{��� �����8�	�Nѳ��ni+U�Q(^m$�:wS� R˄�|�t�Gb.��=�ճ����V��f\ui2��Y�"ڝ�Y<�w�a���ᨆ�=�D�U����X��h�6�.���C�䖃k�����UL(0	D�j(�}�>#ͳ~9<���>y*�|�p<7�^����5���9�3��mԁp��c�1�2����z�P��1��x/���nu�E�7��l��$�w��ZV��0�c��`~6ԥk'�۳O]����-��a��
<�����$��yFԨW����g쒟 �5_�|�Pq,���U,��M2�^�l��{�v1��<8�K���
B�� V�\�O��Jr,��^�K3^r�9�`�N���ג ��8���*�n6r+,\����Wz��c7�}�q�4Ho� G��XX3`��\���z,T�u? i�Rȁ�1R-V���U3�\@#Sm�M��/H�@�掋�!t�]����d0��ւy�xw3L��C�rQjhZ����:�?O�tE
[t�-�Y�����qE!���/���gE�5��0Hq�^���XN�] ��� SR�<��W�e�GV���J�JG��J���鳜	�]�G���g��LE���K����M����xF�Q�i�I��h\UT�[�Ӆ2J�nV��VS�<�u���L}9h0���	'�?h�>`��䃲��n��b�V�Ih8�!`G��otXm�d�񝍵e>#��l��zd+�d��A�,ٝ�;�/�/���s�Av��<렶�p��l():����������7*�^�wL�p�B�����)8���+�1���U�6a��V�&�>��a�W�QY�;�i�߭�@��|�ȀU��6\�[Z�t9D�IlX��.F��y��gY�9�*������z-Y�5�S�Й5��\,�9j R.gt�T'�%p�LCgS�Y��l��k��vM�����z�N�8���8j����-L��ּ�m5���L��#B!���-�7ZC	���K�KU�8��;���خ�Q	\��vyWFy��DCZ]zPB)�`Vo�/6���v���`��Ӟ0+�-��r���_�k�, QOҘ�:$B-�ګ�Z��ȡK(�=��Vù��;�^��B�gg��7�"�?�m�G�h|RpK:^�2Ir2��䙤��K��Eҗ���$�as����P�]���U��1RΓ<�4���^�0bp�'�fJ��ݝ����:�$��wh��:?|V[箯.I�O�xm��Y�:7Z��_��x0]�1w-_쇗�U�t�)��yj6��eZ�ys�
(�zA�8�)�.� ��_"i�t:+�R��g�JY.^�֜.�B9� $����>9ϖ��"��u���K�PF������r�Y�\��`d���4ݩ��esS�}!η�2���=a�,����rʩ��|�%�.��&&��n5CS�Fv}� >|���1�"s&*�tADޙ���D�����|L�P,�#����Q{��j�G��K��1s��+���zq���|P�Bj��/X;���2���0�մ�O��'��OF8q��:M8�=�4w�YҔ����*@���]����c�W��D}���}D��}5q�F��o�C)�?GHyX{iœ���;3{[�ʗ��&c8���4��'�'
����v�H������-�T�}(�{;|<�sb��z� ����ΊP�Z��	
a��
�7�5�3m2G+5}��'�Ι���6��{��(��3�����Ԭx�̓���@!��h���Z�?�4>�      F      x�E�Is�H�F��_Q�>���p�9�Z�ԖjQ��j�K��Q,RQ�~��P�����p�ϟ�#s���Mp�}���F�{������7�й|T��شݩvO��B�Q�nS���{�o�+GcwuU��{���Imp���ݧ&t<,5���ס������2C7�����듛�f����u��]Lup���]mc���yn>��XL]��*q��]v6�2w��E����*����(��U}�
�cmر�,e�������M�b��n�ķ�X�װݭ���r���m�g���64.���{N�X�.w���e�Q6uO��5n[[�t�ʹ�2����P��(��ȶ�5Ou���ݲ��Q~�.zn;�����]p��(��=���]7<6�=�;ߦ�}߷�)�[߸<�{����W�VʋQ^�;���>���:=��c<P�~�w/M��톧��Q>q/{�Ŀ��q��˓Q>e�.E��&Uۆ�̧�|F�TD
م/�Q>w�&Vϸ�+_w\���3��?���V]�NX_���g66n�m�q�+�Q�c���!}���Da�~ŮK���1��%��+��W�]Q���;�	��-�����kJ۽?������[�v���pj��騘���4'v��(W�F��-qىm燇�+�RQ������_��ʌ���/a��M�DWf�2wD`��u2ߖ��,�S�N����T��ļ{�c_��=(�Q��x�y�xTN؄ZN�>�����)�Q�����騜�E3���m�w�F��=��h��Z���|4>��|w�{��C�u�ј��_g���-�0�y�����n�C�<��1(�再o�hø�p5�V8;���a�Nĥ��'�3�'�Մ�=l���{����Sw�߲�;mfU!cmO������l4F���N}�mQ��n��y����sD�}�)�$���r�{jR�I!&(�r�'� ���w|��hR�C�(y��N�0�;����'��.L&��$a����E&S,���.�X�Ta2#Pt�%l����$�9OD�U�Vz0E��u?�?���4�yGI��4R�)j��ȇ4�+b0-�����>�C�LqKB���cšy{��S��vd��3�#�@��@�ߧ�g�I����W"3MeR{�b(�р�ܤO�`sx#QHf��� XX�N{���=�c߽��iB��r��q!�Z)����0�fI�^0+ٛ�8�I[���v�P�ջoڽ���&��X�$nk"r0�bA��Zz0��eHj�������]� �zJ��`~��Q������I���]T�l�I��9���9����ƔaN�̻��J�҆y�����u� s����1�<�:=׾!
%�	�Í��C��،D�I�����j	�\bW�Ɲ�TXR1'Gq2�z�ۛ��{���}O��
�Dv�Y�����)m�HEv����	�]�>"��x���7Iy��t���u=�Sԁ�{6����a�w;�Dv��PO~S��RɺgS����MȻg�囵[�)�I�l�+�d�?^���F�ċ�NX��'%w�D��7��0�$�K�#�#��JL��W�B @�8�
���?��F�~���4!�&@b�D\��~	F��F1p.s�o��)�8Qʷ��uk�B`Y�ģ�H����7�	Y<��B��:�	V\4l����HV\�N
���IJ2�b�_�VJ�IU<�p���:R����-b��6��d��%�ʏ�"
��~�^�x��J,�{"Dv#���Scl�"��N�vUsp��А�X�,��89��Y�Z��6�8�_�n��2���c(q�\�l<��B��1#��Z$$�&����������AA2�b�����I$�����g��%[�Qz��d�ſz�\�.�AH2�B*�a�뀋k	�k�>�T$+�ߺ��8?�:��_\u�k��#�q^}�j�ѻ2
"��w�s�0_0� ���obR`�WJ�Mol�|d�ƽ�ł$ԕ�zd� Ι~jN�v��h�� ��)(c�x;l�QP�e_����k7����q�v/�a�4s�4,"��\���и��^��g��q4p�ф]�� xҎ����Æ�V	�˞^���,�Q��ϊĥZ��od�ǧ ���'�%5�9�B��~_�~@*j$@��㑽�4�7�*MEʥ�;��#���7�=��9��.5�>�?↬H~���x�kEH�j�_1y��׏�Ԛ�� dvKJ�o��J0�G���M�(�I@�"1Y�|����"����f�`�`O:�\�Q�a>u�"��N���~���Ȋ4�t{�]MD�����]���!�N��^�hX�� y�%9D�I�<xD0\�#e]0=���bC��A�ե*�	���K��8�&`rY�X���%�PP3�z�d6A=R����M�"M�M.�B*�vo��L�d����")R%@	� �l�"E뗤@%�#i�dD즁L2������h�J�ܛޭ�)�eX��O�������
|����Jr�� '+V�^
�.y�b��'��2!w�G:���%��h��F�R��Bq�*Q���d,����:�Q	`�D�t�^�n�_2Q	l��$�R5��L�sC��R�*�Ń$<�353Dr��B�	#VB�T�������$��#�%?'�����C8�i��������w{I	�� 
�F�����(@���c9�zD�����u$��O���SDW*7<y>Ya��o�-���[SG�Ж6�Iv����i�ᓫ*��>��6G��To+��f���,P(@�����*`T%Q�R�sv����`�C�d���(��1Ieu�r��GII�\�$N���;ͪ��������e �#1�ѹ砤z(or�D�~��ǚ@	�Ǚ�u��0�e>9 uk��.L�FD�٫��Y`ɍ�ǟ�&kp䲬R,�4^�pk��2��Wm�X.y
;PXe��M���P�f�����bwR�29�[��H5.��됶�k��JiH� Y�}T��9Lr�a0u7p ��%X���UA���jrX.%�^�<~А,�I�~Ca��9L���u����P��F&9d��J�-#!Ʌ&�C�}���UN�,=�=kX�^�f�$9|rg��k�b�<с��O�Qb�R�<����~D\��O�#Z�N��I�|��F�����r:ұD�KJ��(WGo�H#Ɂ�)�m�)��#!�P.-k-S�|eͩ���������{	r�5�eMX=U��$�?�Ӳ�������D95����*����)�U22�6�$�QU�"�C0@��UC����v�尡����MQ�\G�b'��DpJ6���w\r�v!��LTs7p��z���^B�����N9G���4�'��E/���n���"M�E��>���R�7����DD��K,*c��<C�)Bٛ�LTz[����a!l�,�N�K���@�e��4��R��6m�d�2��D�]8M�		Xr�v�;�O�鏦$�Ʌ����"l׉C$%�K�7��^g�z&�R�08��?�Pi�Teimބ��C�$��خuXW�݃���]����'E��1�	Pr�3=����-�g���޸O�n�ܚ�@$��ў��AS�$^M���jB���K[	��J'�I��=7�a��2�-[��&
�����J/�M��1t�W#�bqS��z�Z�P��P��ط�Cg��|��1����s<�&sU���
T�%�&�c�|�&���%��@�S3���z�9P�{�q�i��\� !����y�HJ��;����eR�,���P?������v�V��$Lr�&(1uM��\�e+�>���b��½�h��'u�5n)����U%�+c�R����[��8��,�Ǫ'\������MhHq6�h:��?�k�g\��m���F�=Pȹ�N��%)���~�U�_Z�G�I�0��6X3� A�?�x�L; ��~���ES���Z�ݳ�VrQ ڂ�����" �  ���:m�Y[�
k2�>�$�3Z
 �?�ķ�&�9H1�\R��6�&1�����]�m��\Cc}�*oE=hF�[�o�R�>�Lv�.�.��E>����sX��2��Կ<I(���<�>[��p��A)Ծ�[�� �U����5���
�R�\-2ҡV�K�靭U{�$3���/bC(�Bh�Z6_)��T&�Ʋ�,�"/�Oϱ]7��@ �Q��x�F,��]h���MX �N����*��w���h�"�.�jm,Q�����V�,�7n�U^R|-�B���S�����H�V��WP�ġ�2~4fx����(c(-6�=�/q(J=L��o��f�Q����:9�`���w2v�QZE�P@���߅�렣#}�4��9t�D(�PC��o箰E'��Jʀ+���ic��Q�[��Z�Tr`���Y����g�A�Jg,S��j	�ƶ��i��O�E)�ʫ��i���0Q���]����=RQ3� 5�����˥�N w��駆��R3z�_+�m���@&$�$�:�q�U ���&�l�U�I1��G�����W��@������P�#�Q���Xu^M/@�-LO�q��b���`�ź��L^M��$i�\��V��sk�$� 0�u*��X�Wvj1L�A���}�0^W�'���˚�X���< �jV�$M����g,E_��������������M> ����i_��J�j�������*�K?f
��!�u��J*	j;z��w��xN���-�O)��b��>��yP��V���2�T���/4݀1���?�v�I���*�cN{h�^jb�N%-6o�4��!�e������� �\c6��07Y磘�Z�ej�����h������X�އ53W���Q���f��l$!��M_����]�4�h�	�}0j�� �iw޴CS��J�__`
�`�b>�sQ݈���@��w�Fܻ���Qc�3���g��hNj�f\�-��X�B��K9�i�FC6O�˵RR��
�h�Srylsp���6(�4�-A�g��[kx�uR�:����hhh�^*��`-a��h4�j�lƥ�0�^R�[AG)�0���|�f)��r�z�.ڇ%�A��t7إ�����6=�'��� �gΏu����J�R!��&�:��nh�����L�h���Rf�a��a6���	�t�|��:��iV�"K���G�i�.��F��MM���xKH�Ȭ/6N�_|���c4]@�6�J����v-�r&��!Oؼ�C�C�)�A"�,!.w�g%��pX���I	����F���>�����T!'D�����ܾ��GS��Ѐ0iF���K�C��}�����y�Jl�P�UDa��q��|�H	|(,4y�:�!$e!��+�]�����Ϊ����#%�S��ZERB jG��FǑ�R ��)��Ph�3�R_��Cĩ�a�z��.��h]<lӇ �}�A^G�U�>��iL�;�Sv����:�>CZ_{@!�:�ZP}e�e}���o%��A��苏rj8X�1n죏R�u�E����s�e�����V��!�?)<�v՝L9 �_���2�v<��2[��.�6�)��[}߅��;.u�s�e�*�+c�m;��f0%�q��O�K�r`�q������U��[��S���n5|���#һ{��b,<(26z�14Cw�<V�+omW�@l<���}O	osS�<l�ɰ�����x����J	x<��Z��&����q���m~[���h��IIA
x��-{��I��a�.�P�[?Ͼ%�(��>��q�bR��JH@�W/�-}�G Q]�ջm�@崰ވH�%���l�+��uï�0����-��>��<�7�]���X����~����I��bj]R\���c�n�3�rf��2�=P�-��q��ܹ���bf\o���C!���>)	��A+fV�7
�!�H �p��V%�0U��V��(�4��������'���!rr<�Yk�8�:J���#���̲�$�0����Xo�@��w�>��<�����/ݍTK.��E��_ױ�j5�3�����ˆ��6� ;~%�=������8��z��h��}˧�p����\��%��Io߉��q ��`��>YB-��F�����<�      B   s  x�ESKs�0>�~�o��~���@m�І�N/���;���0�뻶qs�h���R�����1LE�R؄�;Ss�����2��{]�϶P9,j&ߐ�m�vW��	�tg��h���#m�h�d����Y��\�%�pR�����<���=r7�-j�VM�g'7�������A�Y%cX;�Nh����V��JxM��긌o�U��\3���I2X!��6��JD��#	��8��x2d{~�z�����l�^$�0(�6����l�U��
�<��X�O,��JǰB�4�^���c+��u���]�4��*��x�,��J3X��\��-ڪ˅�<����*���u���E���7�24"U�`WS���{1�������P��*��۴��Ő�tۓcq��4��`txΒ�����K*K��ug)Wm���DQxӆ|�i��#���'���	|՗wx�Nƴ˲�Җ;�ȩl*o��0*���,i�cx q�����m�T����吧 %¤VڂP��Q��(Zi]��jr�amo�'������Ky�_�9u�w}���*�o�q$�R�>�>�|
ky�j�_��@x��:��/%33XK��Ü��r�� ��}���V������B6      Q      x�U��v�L����SԬFu�H�]w�^�$K�t���י$�	x�H���~;������DdD�Mz]���5у{�u�g��s�m}t禵���2���>����[�������w��]M��Y]�m���u�,�֮����׳,�6E����5��xS3ˣ+��6�U[�U���jp/mWF�;����,Z�\����M�0����se���?���b��+]����\���yoݷ��wn6��_���q���jf����E�]����i�ЎU�GW���,���]��tI�ߚrBK��ټ�n:_���0[����nء�9|�Տ��fVZ���(�oY,�G߽M�����lG��zW;S���P��j�����<v�-������ﺶ�-2��5:/ݡ���"����\��]O�E�jX��Y�����X��,�k��_�úӎ.�ї���;?�C����n��r���R��٪�����m|����v�L�˪��6z�|�2�>�{.��\���Yt��ލ�K�ڱ/���q�N>W��u<���x�gO��;�խ�l���Y<��]�z'l���5��0E�ݦ=�g������'��q��wU����,N���}a[�����9�Y�F7m�yfnf����U����7�^Whhs_5��j1���7=��,�u]���׃�������v�,� :t�&��ix�,�#��n�ׯ�w��$��V�̧ixy�D*}��%�Rm�4��|��םl$ɢO�X�f�5KPo�v<!����o�r��W�k���x�,=�~8��C��0e��f�G#��Y�����{��u�����+���i�5�ɳ��f��yp}�x�d�S��o��MR���J��m?��4��ᇲ�;��͘4�]�x1�e����Ċ��7���c7�Έ>M����7�l��[�3k�U'D��H�mʖ,|������/�n������Y��׺b9�Ê�Y�b�,ݼ���v�e�߾���&���<��K�D����+޻�z��}�����S���N;�ݹ�,�s��v�VD���S�Y4|ܜW�|������C��Y�k,��뉮����v��㱟�)v���D����4�3b�o�8���%y�y��6zz!!/��{}1n�����/m��f�OS #2M�b�ն�{�����*K>�+�z鬴H��Gt�

fk�75���/K4|Ӿ�zLF����1��w�c���YH�C�ﺨ��y�s�� ���k@���\;��>�͖=xC����A�̯|��L��N=�A�{tcl�1���z��,!,!Z����L;���+Yh^��
@9�I޴��Y!\�}���k-R�����ve�c��o*{�9�g.G��}�<�����ߥ;T�{��i_��9��vr�}mM��`���]�|а�U�������@�j��|��0�Y�oi)�	>LW�i4��ꃅT����s�^7T=N0ކ�p�z�xn�Jx��n���H<V+
Wv����0$�
ػs	����Fa��> C!�dw�] �g������p�W��<�u"�<DCGP�����B�����,A��	.;y�@$�Tکm�''xK���~��e)�"��vK{A��B�����Lv�c��w��r>.Ħ7 ��n�cq$ި�K�s�wYm�vkk�����;�~@v��u�\��ȿ�}��~�cJ��#OZ��o�# s��I6�w{p���B|���=Uh����x3��O%��G��!���-�b��0�½���牱Qb�e��Zs0�@��<���^u�J��J<#�q"oZ6�\��i��}�.�ۦB"����5�/�~��{�v<&�jҏƠ�;{)�<l/��"Ђ�9�y���}�u��s�� �@���L'��؝�`.��M���Њ��w���J�jbR���Z�e��ep��C�� ��r�9R?���&��Nk2��
D�Θ����m�F�R�m[+S���~�o����}k� pA[e�Tp�I�ίKED�U]cQڶ��"�_�Mܺ��*�q[���������P�1&��U��2�9?K+�#�.�x��:���;��w<N�q�K�,�6o��@�-(�쇎���P��n�gr@t5���vFKF1��s��|kY@z�v���5 )�Ob'R�B�0�)��^+3t��B,�e&�����iP�T$h^$fK2e��
a_�?ϝۡ �*�pl��R�B�/2/z�X	�>@�Q���N�+��dG.0�ʏ�R_��BFm���-��	�?Q��ي�,�F怷~G�I���cC�"A�y�U$�u�6}�3������Y,�{�9��\A�S��n�����QM/
B$�6J�΢�>4�a��GO�Ҡ�{��5�-�B�K��&G`�y9�@(�����F�A��, �˶�(єj�?d�hݤ���
�'��.y�v��#ˣ�jP��f�U�*�,h��ޓ�-,U!]� �z< �VG�qZ� nojx"�Rb���0��T�X�
����"P����x,ոכw�G��g�&'�������@>�kݾ�{��jk����K v&�`�v�lX��>`��A3 Y$sm�mE�x�R�K�q�������,.�K[ ��>{�#�b�C_l���\,��mt��A��~���{��v�1����z'�>�M!*,�c��*l�%�O�>7���{M^^[j(U�Z��i�)�*?AG���L����#>.b��z�lw�Z���۷k9�4���<�&��(Q&�E
�Z)s���	���.�^�'�d�k. w��X���7s�D���q��#3��7*1�$�^B��Zj&�u*e��Pa �����`��uyP�`��@�7���ȫ��'��]GD`�亍0oA��� gQ
6���ٿ!��&���~=�keZ�%���7W�\�)��4�
8ʙ�-�����9��I�S�V`��
 �H�~��WޢU*�QA@Ag��O���۝4��Y�����"#��J�<��B��T�2�[背�%i�	уxmw@�;��W�=�k�l�J$�kc����!��'��K�QZ�������5��0���E�P+Ҹ aU��\ݷ�6��0��RjA� ��u��l��@�q����r�0��ܩ���i�kb~��>��T�׽�n�_ ���X˸�6XW.��� ��.)�K�p�?vf���"����5�N@�� �Ma��'.��ծ
�d�:���x�l�C���V�;�.<n�ڦ�-&֛lt���R�q��t=�5�[���n�J��/��gEn�1\o�BP]�)���l	�^���
k~+%i�,�{�\�F�����a���M�F�$�m�s�����zı�]�k��-��`�W��{�K]�B�_���y_��b�����*sT�Bn,�]�1~�܂5X�����F���'�TW�B��{��WMW��ީd�#KA�0	�P(AB���z�r�ew'2b�5Ox|�����XI�#Y��[�+���[F�q]G��k�N�y#�V���_[��h	I��S�j[�v�D1��g�Uě��J���_�1�C�N95p��x�6s!�ߖJR>5��������^W
|�`��������$\�K٫�ޝ�$��O1~p8V^%�3E�����@�*w��_C��B��*���Y���u���ět�T�$~ֺ6-�$*��t�(*��*���A����OZw#��T�PR�\.�c�����!�K���p-c�ƯR�y�n�X���vl���0JdKE��v��c\�$d�ͻ���B�z)��������Bb�}[��*XK0w�~I/Z�廄ei?Hv-�8x��|XV���c��wT�H`��
��!#���X�|U�	B�Y"����Ӷ�_��ߠn�j�!��e�[A|	�^ ��zm�Ȣ�~'jX����e�,���� ��+v��#*��ː�V���zo9��<n��]�\�����m�l���.��)�ME[�Fp�lĂ��%(|/J��/�2    �e*�#����e�g�4;E�}��ɺ7?�aT���6�%o���"P�a�<�/�GK���7�?�dg��Vп$����Y*y�gl�[[���j03DN0E��뿼�����t�5�OC�E)3V��@���E]�f�I+t/��˺�/o�Ԩ��)1������oT.W�D��(���j!18� f*���YV��W�?��:����v`�j�U��$��O�|�Is��j��/����C�b�tQq��Y�n	?�<��r7*���E�.Z�%*+����R���B|��n�v�B�*�&�G�^V��ꅖ������T�Q���ʙVJY�*��e�K��ݚ�Q,��'���Ɋ��X�X�?x[�`By0��L�����X�/>SemT�MCq���#^�$���q�Z��J���DE��[�(>S�U6��n@�G�k�C#k��\�� �������ƭ�9�9(�J��-b7н�Su��*��xi,iotӃ�8b@�Z�%,��ˍd-M��� ���������������6�RT����W�<?���D=U!!�b#1`z��+ CC�����*��W
��\1h����×G�<"5�����c�����`�
�f��s5�&�?ʺW�
ċ"lh#û�5Y8z�E~���Z�z~�Q("(�X�ˉ���_;��0RG����˱*՗T�
�V�m�����X��7Q� �'h[���_��ыP;e,���8��Y�5�՜\�'����x�Ѧ�+��f�cuG�Ư#�1�H���X=�{���z���bГ<�[!�vl� ���$��Wb��AE��N���/����Tˠ�v�H�Ћ���)���U�>	>�ˠ��/�_��z�|�Fp �9��a0WQ�8�����Ebe�V�6� �\y�ovv&>�-���~3��W5� n]�p`�/�ǱW��8zi�D�S��S�ah���Z�R�~_��S|^�c���FLl��iʂ�`Yxl�bQ�WZ'.N� ("�פ��.���2؎��*V���R�j�%ȥ�j ��ʊ�� �U���J�+��&K���@&7j�O*�� 淮:bR�#�������*���0� D�ԝc���뒧�,+���V�9�K�����]wJ;�k�#� ��D8�P�[{�~�oq.�َf��q�ǀ��d6�Xe��\96}�v�@�c��[(����hg��U�vm\�!J4j���n��`��\s$*�
�TC�W�2�_�}il%yt_{��;+:c����*��w�l!�yэ �j2����V�#��6��NpA�_O;�5�M��� {�~��ǀ����*NJ�b��-_�<��ybI��	��k�C,��gxe�D;2"�n缥�h��|��T5��[�9K�BabsjuA�3��4���*dӖu1욥j���S1+�6pcI����u���-�n/G��,��*.�ۜ��	8�����w_]3!������ ��v�^ģ��*�	@����I����S����h�"�fU\Go�,?�?�CY.�,��}�M��?m�+O:&e'���Yp��{�?�� �J@N�ztw~J����������]{r�_TWL��������[�'6d0�j�6}�cc���Pc@h�X�`�4ſ���9Y(m�$����De���V=�E�ZMr��}թD� �?\5��i�d!r;x�#B�JYIn4��j�^�'k��ۣ~�v�KCX� ��A��P4J�Z�:z �ٰY���v�Y����ޚ7�s�m�`�&/����������Z�0��4����)�ϧ��ʶV���ig��$V�a�:$X���uT�}��q8�m�j����vݾ�j���Z��߅�~֮���A�T۟5��v6X���҄�n�KGxՠ���[ZuG\�'��(D�DK��64�����}�Y�����ܧd�z�40��V���^��
�	`��M�[tW٬X�Z������ m�(!a��A�*���q[�@�`b5z>�=��c�w�|���H +@Qa#z֙xi!�	�*D��p4�M���/��(�5��d5�7b������%��;�א
�GׇI5@�O��w��6�;,����4�y���S���پr�K�@�k��8�e�k4��U�����B��@�i�Y���P]1���%0������8 �ά�4߆$�Ԣ�	�a�A
��ɚ; �����o����Y�-��	��Tk�j���7+ �����
7�gT@�!�����0����}S��Mw/�|�G^�9�e�������_V��+�&@�u9�.Јa�1����-}ԢԋH ��@rɏ�c�l��:f��?�Z�����
�p.�ٺ0-�Aڔ#�(��k�^�}ݑ���B�֯4�%��T쪷���?�f�J�2�\�;eKI����a�D0��k���T�T�6��`�6Û��ቍ�c4�*��r�Oъ4j,!d��Э?���L��m�GUhR���ھ�QK�*�Y��
�7�bɿV�
J���7��R��V�Hj>d'��f�Q�O�f���	dmƉ�������`�\f���l�Xg*���H�D�'CZl��1O,�k
g��vV�.h6�F]*���,�<�Y �J�dT�����o�*Cb}�p��c
��)�.�g깄,ԉ�*M���{4p;���#]��}�I�ɎZƍ�taj��Zl�B `ˆE?���[�<ש	�u�J���T�g��6��Q��{�ݨ��V-�,��$�OA��6���"R�[Ec�[^�=ZYơuf�>��W{]�72leKK�.�`ns�����Y1~��L
�~�r�W��M"u*�Ru��լ�[��f=7�=����������IA_榀�N�]
���� � �il�z�+/<0'IF~�>�����?��cc~�$w�:s��-��j�P����&f�Q-s�i��,u-ml��-$j`5aF�v�&�U(U���O�4Y����/[E�n#����G�(A-�7ؔnjlHlT)��2��f���V&i"��7^o���&��l׷�ͯY�Z���E�'wCPȋ�7JAcc]����y��}�G�������=�`���Հ����=YzShH�?��uV�K�^�p�����q�O�i.�qKRdp�ه{�D��Bkվ�V�f*tW‪0
2�li�l�
��M����;9�M����Vl`�����X�T8��F��LC�����a�E7�p���f�0���B��j��h,��&��>ڐ���^Xj�k�؆<��l��
S])`k3����vB�Q6���,+O���-&k5��} \a�r��k�+�vW]� �U�T]ݵ64���ZMi� �GYj1����V�K���W(�F�m�75��N�>E ����l��&gJ�؆Y6�]
�j��#�%���Sjޒ�6@0{1ZH&ڈt +�,�4�w�,��m�U�K����)ɷis��/�4��:"p���f 
�zH�q��'k�g�IR���W�P���@�ߍV � ��?(`�uӬ$���#tG�)~��u�?��wMJ�Q�H��iͨL��qKf��mm�-��V�"$��l�Ȧ���wd��L��v�����T��>����J� Ӂ bǉd�z^��a�S/,�k���+�6���M��OP���?o�:,���w�4fb��L=\`��&C�x�_���0��"^����_����20�ʽ�R\~�;�FD��?���Œ���ӫְU��a���+�E�O��T�Be��6����Ҹp-'�kD�>L��z����e�SaV|l_������� "	p�~����0���z��GUY�pDP|�5��Z�Ϭ/8Y]F1M�yh�Z�Rs}Jx2U�	Ģ�cm���-����V�4�mjKDi��_�x�^�0��YgV������j��T�u(7|m�EY��A^)"�	�,.~GNj�fj��r���6�NG7�����*�_��y�����>�ɒ��;�M����jŪ˂���h�ib��W�u�0���f�m���ԅ=A4aN���nњ�*<��X��R"m1:S��-i���Vs�Y: �	  Ø�"���b��	5���R[K?}c=K?�q6��a|�4�Z�jC�T����T]�jh�Q�ۦ�Gc��]��(�^QXRcX�U�*g_�tHf�,xd6[d+"��,���՛HEԷȬ�,�����m%����9E#vH45�9c��-� �"1^�u���
a����c5�`�G"�^/(T�Q�}۶}�N�����k������N�͝gJj����a:'�m|q���2�*����ن�:�Yn5��kL�ߩ��v����������{�ԑJ
j:�����Z�E�mӸ�)��q�¿r֞�4��\C\�Z��Us�4�R>^�K}��L�Ǯ]���H$�������
����z;�A�(56�h'�l43`��f"�M+Y��=p���P ��ڷvi�=¹͒��_��\)?[�G7�tZ]���F�ޭ7���������6��5}Ω�ӕ��	vNhjt~.y��P׷��B�������C$ �A�J�fX����v�WZ,A6�O���t��.�[#��c¥0l��M뛟�S_���A�\�ce�-U��[[۱��=��V�;�+!�B�V��C�[�׫ K"�Jd��&��(a�PA�ଵ2X�8WA��E��^�*_�5Q���[�B�����`x���0\�A���3�u֠ٓ�������h���\PZ4t�,�z5�#@���N8tgg��z�u�V�����c)!s��;L�b������\�Z�VGE���ͣ�4��+�Żv6/����آ�k�	�P���������A_���I���G)�p���S��F�MK8I�*��VNQ8� tdxw6Ҥ�w�FVn,��XǢK;<Yk0��^�ڣ?������,�}p�7��ѳe�9����-��t��п5#���(�	ش��Jj�Ӱ�ؖu�vj�vq�9}po��D�!tw����.w����C�n�%����q N3�9��Y��%;Y��#W-9�U�6��܏|(96W�ئ��f:�E�'�3 ���S�:WB�U�:h!SR���XiҕMk7.u8Tuw̉OJ��c��$�L���Z���Q�a�19����J���
9��c��ʾo���J�6/��k�$��V�S(�a����ž5h�M���л8y�Q�<[�!:�[B��\|�~���y�\c�"�6S��:��՚$@Y��*-�;K)�L��4�W[����W�Y�^UċZ�D�D������J��\+߯�6�Չs�O����|a.6i�α��k�n��!3�o���{cZ�g�X3U���/��ߝ~�?5рN�ʆf���G�l���p�]� ��:�������î�;˃�̭i`M|��ve.�e�U��QȼX�j�m�W�DvQ�qj[�j� p����9¼Pr�-~���ѥ��>F{1B8-��o��o���u��`H���
A�WQH.a.���T�R�ђd��㮅)��CKu��j�Y�|�F��#�0�&z*K��l����]�$=u�Ϋ`A�Yf���<��&4�
;룝��05Y�����/�^07����hǖU��^�&���7�Y��$�eL�N&��7�/)���Y������Q��Q��0�rdm��֣�Ku��V�|Z�fY���M:�0'_h2
����/lQ�Y�� �����g�#�\��:�2
a��(BN�j��3����<CQ���Z��г:ԴPa
h�h� / �+���8~�!H�5{�e���jڒ��*��"?��ѡ��W+1ٳG/Z���\�(�����q�ov���TGvFo�i�K��#��i���~���k���K�{����A�Qh �(��i;�*��OaJ��o�Z��|�BZ�>[o�zd��=�Cwz�������9M8]���"V���
�r�"^~��݅�年8�3_���P,/0$�n�O޺l|e�Y;]\��*&��:� �U1Y'd-cv�i|� ��U���Ғ/�� ����K�s�����'\��ht�f�HG�# ���X����l��/U?�:��v~۪�}:��� C)�fA�#*'W��%t�[3.�F�EA7v~�F�
����>�p��6S ��i@\��EjH[K���" ? Z:X�r�� �>�}��g���l~� ���iZ��~E���Q٬��o�]���؉F���dE��"ۦ�o����������/��4Hj�����ѝ�2����H�U(���t�W�� x�i���Ɉ�*� ~p�5��%I��OK��e���_�ij���f�]S�UM|��4�Y�j��]Jb��yH�';ٰ�B�8�����5�;XGE����[�G���]}����7��\5��4Y�5M\X�t�́r�nzC�agh\��|�~j�E���.�&]���2�������=_gsǍ�W�\T�F�B������V��Y� �q��6 R��a �~iU�º��ۓ+� &H3�E	���;|�_�����jk�SՈ�h�"���jB:5?�Q�N���͚���k6��7H�      D   5	  x�u�[�)D��3���Zf�똤mW��
��D����J�-~L��������x����u=���O���˯��R�����J���/u=4��د���e�����g�|���w�h��CZD����xFT�^��ߚb�����Y��h�~�~�y��45͑*�^�@�GDm�����t�񚛝w��|I�s=S��f՚�DLI~��'bF�=?(洕*�b���hm!V_߱ߚ�V��k�vf��:}G3��� ��Rbo�s�0ů8x4�"�� �=���8нێ�wR'��\<^��[�J�ߩ�t��N�|,��z�wp�׆��=�+��M��H�K7�³?�o �;aN����">#$B��v��T�F#��$:�i�H�o��!1_�rdJ-o�H-R�N}�M��R3��:����A�#��7�7��F��'��α�K����x�;�NF��)��&g �Mi���P،�i�Ȥ�� $�w\Z�^��i�T:P��Z.(l�F@a�S�C�d��Sz�p�#vN%�ҍ��^�t΂7.=��	� Qr�Jgd�
{�p���>��=���3��B3H ��{ ��hd��d8'˃������BF�I���h��Y)P8X�
Ǡ����!c�H��B���
�ҡ��N�B��@�tN	I���3��Y�;QU&����ٿF/P8%��`�1�8��\֨P��<
jQ��C-�q��#�ѳ=�v��y���	�soTc���Qa$֍D-	�,ި̯"�	Ɋe����
zq1� �r^,�
��>+���IT6ȞCPBs;���O|�`�����:*���i��G5���ࣚҶ[~�͢���l���AZ���v�E:<�a��\�PR��a��!Ԁe��oA��_�g��6%�)�q�Ƅ(� �h�d�*� �i�TgRd���
����\p�޸K�
5�c#�`��{�E��W�̷�Fp�a��uRfP�2���������C�����3njT��4Ԁ��C�CP#:�֟%�L��Ԉɻ||�����yX���$?߂�+�]�`��0�Fb$���UXV~���6��.��ra�Āup�:��};Jm��:��.;}<�6VaA��UfY�l\a�X����@�\%v�J:�(�h,E:��v%��A�A޲l���I��$���]n�@�n4Ì���jlG5:��<;���k����u��8t�7��gL�|j��ԝ�</����J<[/���%���#��$��f���j�Sv�`�ax��~�9�����9&a0>���s*�</�����%�[P��뷠Ƭ�:9�Ϋsl�NN%ߩsp���:�se��Ր*��NnEC��0$[��a�����h`�ұˠ�ax��#������vL�``��1���y�iM�*��ݵ�
�݈��)�?�Ӕk��r!�rO"��4m|OUn��0n{	-�I����: YV@��ki�a��t?]J��r���ӷ�8O3n��j���թ4��8�ӌ�<���n֭f��<7W���i�CBׯ3<�هgA�i�jl�
5��U��,ͯ�m,�AM�r5��g�j���ӜS��Q� '����<�)�p��y��9�O�r���&���ӂ[7�� O�����JB���G(��b~�� �y�ւg����bԫ����n��� E���\/F�j�yBTn����*�i�v�F�̓��B��4 ��<����?<�<߉bW���9}j�K�Ђvp�A�*W7	�u�Ѿ֕���8۔B�6h��i��i}��_M�S�[��y9Ϗ�����IjAjm�^��Sw� jt��?�<߻Z����vڛ֯�PcZ�6�Pcp_ˎ�a��g��`�U�����nXB�Q��y����K�9�1��g�k/n�f#h�spپ�c�9�I�Ƽ�@sj�+�&!��d^N�n�mF�.xΫlϷ������sv�����Z�vZ��pr���^X��J�ӋR��z#ƽ��P�p���#��%���+�l��sj�e����<��eh���rً}'��=$t]�*��$����}�Թ�oARh��@�\�%!��u5�[(����O��t�D�U��:� �4���`�8�Ӎ����t��$��"�0�c��r㔺�k��]�"�y�q8� �������t��l�AA�\�纠�vh�vȯ����!��6ˡuU��<݃�=-�p��ƺ-w.�3��u9�<?-�q]������y�oA��y&РFp��;�P#������y��������ks��XMBB�h4�}A5�sF;=O�+6N�Ӄ��8e���<�������.[     