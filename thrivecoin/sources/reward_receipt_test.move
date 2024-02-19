#[test_only]
module thrivecoin::reward_receipt_test {
  use thrivecoin::reward_receipt::{
    ENotWriter,
    AdminRole,
    WriterRole,
    RewardReceipt,
    transfer_admin_role,
    add_writer,
    del_writer,
    add_receipt,
    recipient,
    transfer_tx,
    version,
    timestamp,
    meta_data_uri,
    writer_list,
    test_init
  };
  use sui::test_scenario as ts;
  use sui::vec_set::{Self};
  use std::string::{Self};
  use std::vector;

  const ADMIN: address = @0xAD;

  #[test]
  fun test_module_init () {
    let ts = ts::begin(@0x0);
    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    // ensure that admin role belongs to ADMIN
    {
      ts::next_tx(&mut ts, ADMIN);
      let ids = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids) == 1, 1);

      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::size(&writer_list(&writer)) == 1, 1);
      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_transfer_admin_role () {
    let ts = ts::begin(@0x0);
    let new_owner: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    // ensure that admin role belongs to ADMIN
    {
      ts::next_tx(&mut ts, ADMIN);
      let role: AdminRole = ts::take_from_sender(&ts);
      transfer_admin_role(role, new_owner);
    };

    {
      ts::next_tx(&mut ts, ADMIN);

      let ids_admin = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids_admin) == 0, 1);

      let ids_new_owner = ts::ids_for_address<AdminRole>(new_owner);
      assert!(vector::length(&ids_new_owner) == 1, 1);
    };

    ts::end(ts);
  }

  #[test]
  fun test_add_writer () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc), 1);

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_del_writer () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc), 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      del_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc) == false, 1);

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = ENotWriter)]
  fun test_add_receipt_role_fail () {
    let ts = ts::begin(@0x0);
    let non_writer = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let ids = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids) == 1, 1);

      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::size(&writer_list(&writer)) == 1, 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, non_writer);
      let writer: WriterRole = ts::take_shared(&ts);
      let ctx = ts::ctx(&mut ts);

      add_receipt(
        &writer, 
        @0xB1,
        string::utf8(b"test receipt"),
        string::utf8(b"v1"),
        1706630649541,
        string::utf8(b"http://example.com/123"),
        ctx
      );

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_add_receipt_role_success () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc), 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, writer_acc);
      let writer: WriterRole = ts::take_shared(&ts);
      let ctx = ts::ctx(&mut ts);

      add_receipt(
        &writer, 
        @0xB1,
        string::utf8(b"test receipt"),
        string::utf8(b"v1"),
        1706630649541,
        string::utf8(b"http://example.com/123"),
        ctx
      );

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let receipt: RewardReceipt = ts::take_immutable(&ts);

      assert!(recipient(&receipt) == @0xB1, 1);
      assert!(transfer_tx(&receipt) == string::utf8(b"test receipt"), 1);
      assert!(version(&receipt) == string::utf8(b"v1"), 1);
      assert!(timestamp(&receipt) == 1706630649541, 1);
      assert!(meta_data_uri(&receipt) == string::utf8(b"http://example.com/123"), 1);

      ts::return_immutable(receipt);
    };

    ts::end(ts);
  }

  #[test]
  fun test_receipt_view_methods () {
    let ts = ts::begin(@0x0);

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let ctx = ts::ctx(&mut ts);

      add_receipt(
        &writer, 
        @0xB1,
        string::utf8(b"test receipt"),
        string::utf8(b"v1"),
        1706630649541,
        string::utf8(b"http://example.com/123"),
        ctx
      );

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let receipt: RewardReceipt = ts::take_immutable(&ts);

      assert!(recipient(&receipt) == @0xB1, 1);
      assert!(transfer_tx(&receipt) == string::utf8(b"test receipt"), 1);
      assert!(version(&receipt) == string::utf8(b"v1"), 1);
      assert!(timestamp(&receipt) == 1706630649541, 1);
      assert!(meta_data_uri(&receipt) == string::utf8(b"http://example.com/123"), 1);

      ts::return_immutable(receipt);
    };

    ts::end(ts);
  }
}
